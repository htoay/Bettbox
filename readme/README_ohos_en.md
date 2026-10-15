<h4 align="right">
  <a href="../README.md">简体中文</a> | <strong>English</strong>
</h4>

# Bettbox for HarmonyOS NEXT (Community Port)

This repository is a **HarmonyOS NEXT / OpenHarmony port** of
[appshubcc/Bettbox](https://github.com/appshubcc/Bettbox), based on upstream **v1.19.5**. It does not
change upstream behaviour beyond the platform adaptation.

> This fork maintains the HarmonyOS side only; new upstream releases are merged through the
> `upstream` remote.
> Upstream repository: <https://github.com/appshubcc/Bettbox>

> ### ⚠️ Disclaimer (summary)
>
> This is an **unofficial third-party port** with **no affiliation with or endorsement by** the
> upstream authors, Huawei, or any service provider. It is a generic proxy client and **provides no
> proxy service, servers or subscriptions** — it is intended **for learning, research and lawful
> network debugging only**.
>
> **You must ensure your use complies with all applicable laws and regulations** in your
> jurisdiction (telecommunications, cybersecurity, data protection, export control, …) and with any
> service terms you are subject to. **You bear all consequences of use.** The software is provided
> **"AS IS", without warranty of any kind**, and the authors and contributors accept **no
> liability**. Full text: **[DISCLAIMER_en.md](../DISCLAIMER_en.md)** (Chinese:
> [DISCLAIMER.md](../DISCLAIMER.md)) — using this software means you have read, understood and
> accepted it.

---

## 1. Status (verified on real hardware)

Test device: **HarmonyOS device (HarmonyOS 7.0.0 / API 26, arm64)**

| Feature | Status |
| --- | --- |
| VPN start and proxy forwarding (HTTP/SOCKS5) | ✅ Verified (tunnel counters increase, connectivity tests return latency) |
| Allow LAN (allow-lan) | ✅ Verified (HTTP 204/200, SOCKS5 200, exit IP is the proxy node) |
| Dialogs (Backup & Restore / dashboard info / tunnel editor) | ✅ Verified |
| Background keep-alive (continuous task + self-healing) | ✅ Implemented (cancel listener + 1s re-apply + 30s watchdog) |
| Keep-alive mode selection (data transfer / audio playback / compute task) | ✅ Setting matches the system notification text |
| DNS push (device DNS → core) | ✅ Verified |
| System-wide DNS override toggle | ⚠️ Partial (HarmonyOS exposes no system-level DNS API; uses vNIC DNS semantics) |
| Script (Script) / deep-link install / full app enumeration | ⚠️ Not done (see Known Limitations) |

---

## 2. Building

### 2.1 Requirements

| Component | Notes |
| --- | --- |
| **flutter_ohos toolchain** | The HarmonyOS target requires the OHOS branch of Flutter (stock Flutter has no `TargetPlatform.ohos`). Expected at `~/tools/flutter_ohos`, or set `FLUTTER_OHOS_BIN` |
| HarmonyOS SDK | API 26 (the `sdk/` shipped with DevEco Command Line Tools, or `hwsdk.dir` in `ohos/local.properties`) |
| Go 1.2x | Builds the core `libmeta.so` (`-buildmode=c-shared -tags=with_gvisor,ohos`) |
| Rust | Builds `libcode_forge.so` (linker paths come from the detected SDK via env vars) |
| python3 | Build scripts |

### 2.2 One-command build

```bash
python3 scripts/build_ohos.py                 # release (adds APP_ENV=stable by default)
python3 scripts/build_ohos.py --debug         # debug (injects extensionProcessMode=runWithMainProcess)
python3 scripts/build_ohos.py --app-env pre   # pre-release (shows the PRE banner)
python3 scripts/build_ohos.py --version-code 2026100200   # temporary versionCode bump, for overwrite installs
```

Output: `build/ohos/hap/entry-default-unsigned.hap` — **unsigned**; sign it with your own
certificate before installing.

> Troubleshooting: `flutter pub get` can fail in offline/restricted networks. In that case reuse the
> resolved dependencies with
> `flutter build hap --release --no-codesign --no-pub --dart-define=APP_ENV=stable`
> (run `cp ohos/pubspec_overrides.yaml pubspec_overrides.yaml` first, and delete it afterwards).

### 2.3 Always rebuild the core after merging upstream

Upstream frequently changes core sources (for example, v1.19.4 added a congestion-controller
parameter to `t.Start(...)`, and v1.19.5 replaced the `flutter_qjs` JS engine with the Rust
implementation in `plugins/code_forge` and added `core/patch.go` / `core/bundle.go`).
**Changing Dart without rebuilding the core produces a "new Dart + old core" mismatch**:

```bash
git fetch upstream && git merge upstream/main
python3 scripts/build_native.py     # rebuilds libmeta.so + libcode_forge.so
python3 scripts/build_ohos.py
```

---

## 3. Remotes and Branches

| Remote / branch | Purpose |
| --- | --- |
| `upstream` | `appshubcc/Bettbox` (read-only, to follow upstream) |
| `origin` | This fork (push target) |
| `main` | **Pure upstream mirror** (fast-forward only) |
| `ohos-port-clean` | **Public working branch**: a single root commit of the sanitized tree (no device model or local paths in history); pushed to the fork's `ohos-port` |
| `ohos-port` / `ohos-port-backup` | Local full development history (pre-sanitization commits, **local archive only — never pushed**) |
| Tag `ohos-vX.Y.Z` | HarmonyOS release point matching an upstream version (e.g. `ohos-v1.19.4`, re-pointed to the clean commit) |

> ⚠️ **Push policy**: push only `main`, `ohos-port-clean` (as the fork's `ohos-port`) and `ohos-vX.Y.Z`
> tags. Do **not** push `ohos-port`, `ohos-port-backup` or `ohos-port-backup-*` tags — they contain
> pre-sanitization history. Day-to-day work happens on `ohos-port-clean`; consult the local
> `ohos-port` branch for the original history.

---

## 4. HarmonyOS Adaptation Notes (differences from upstream)

### 4.1 Key finding: release builds must use an **abstract socket** to hand over the TUN fd

Measured on a real device (HarmonyOS 7.0.0 / API 26):

| Build | App main process domain | VPN extension process domain | File-based socket handover |
| --- | --- | --- | --- |
| debug (`"debug": true`) | `debug_hap` | `debug_hap` (same domain) | ✅ works |
| **release** | `normal_hap` | **`vpn_isolate_hap` (isolated)** | ❌ `EACCES(-13)` |

⇒ In release the VPN extension runs in an isolated SELinux domain, and `connect()` to a
**file-based** unix socket created by the main process is always denied. Switching to a **Linux
abstract-namespace socket (`@name`, no filesystem inode)** makes the handover work:

```
[TunBridge] SendTunFd ok: fd 33 -> @bettbox_tun_xxx
VpnPlugin: startVpnInternal succeeded with tunFd: 33
```

Where: `lib/plugins/service.dart` (creates the abstract socket),
`ohos/entry/src/main/ets/vpnability/BettboxVpnAbility.ets` (retry/handover) and
`ohos/entry/src/main/cpp/entry.cpp` (`sendTunFd`, non-blocking connect + poll timeout).

### 4.2 Other required adaptations

- **Invisible dialogs**: the flutter_ohos framework defaults `AlertDialog.scrollable` to `true` on
  HarmonyOS (stock default is `false`); this app's dialog content already scrolls and has fixed
  dimensions, so it rendered nothing → `CommonDialog` now passes `scrollable: false` explicitly.
- **Freeze right after launch**: `EntryAbility` overriding `onBackground`/`onForeground` **must call
  `super`** — the base class drives Flutter's lifecycle through `delegate.onShow/onHide`; skipping
  it stops the view from rendering.
- **Extension killed by appfreeze**: native `sendTunFd` must not block the extension's JS thread for
  long (the system treats it as unresponsive) → now bounded to 2.5s per attempt with asynchronous
  retries from ArkTS.
- **Continuous-task keep-alive**: in the Stage model only **UIAbility** may request a continuous
  task (an extension request always fails with `401`); cancellation reasons are logged using the
  real SDK enum; on cancellation the task is re-applied after 1s with a 30s watchdog as a fallback.
  `taskKeeping` (compute task) requires the ACL permission
  `ohos.permission.KEEP_BACKGROUND_RUNNING_SYSTEM`.
- **Packaging**: `arm64-v8a` only (drops the emulator-only x86_64 `libflutter.so`, saving ~40 MB).
- **Core side**: HarmonyOS has no standard Go CA paths → injected through the build overlay; DNS is
  pushed from the native `getSystemDns`; a Go TLS-slot patch keeps musl `dlopen` safe.

---

## 5. Known Limitations

- **System-wide DNS override**: HarmonyOS does not expose a system DNS API, so only the vNIC DNS
  takes effect.
- **Script support**: requires `libqjs.so`, which is not bundled.
- **Deep-link install**: needs `uris` skills plus `EntryAbility` want handling; not implemented.
- **App enumeration**: `getPackages` falls back to native and is not exhaustive.
- **Signing**: this repository ships no signing material; build outputs are unsigned HAPs — sign
  them yourself.

---

## 6. Directory Layout (HarmonyOS-related)

```
ohos/                          # HarmonyOS project (Stage model)
  entry/src/main/ets/
    entryability/EntryAbility.ets        # Entry ability (note the required super calls)
    vpnability/BettboxVpnAbility.ets     # VPN extension (creates the TUN, hands over the fd, keep-alive)
    plugins/VpnPlugin.ets                # VPN channel and network state
    plugins/AppPlugin.ets                # Continuous tasks, keep-alive, app info, etc.
  entry/src/main/cpp/entry.cpp           # sendTunFd (SCM_RIGHTS)
scripts/build_ohos.py                    # one-command build (version sync / process-mode injection / optional signing)
scripts/build_native.py                  # Go core + Rust plugin
docs/                                     # Port plan, audit and upstream-merge records
```

---

## 7. Acknowledgements

Upstream project: [appshubcc/Bettbox](https://github.com/appshubcc/Bettbox) (Flutter + mihomo core).
The HarmonyOS adaptation, debugging and documentation are maintained in this fork.

---

## 8. Disclaimer

**Please read the full text: [DISCLAIMER_en.md](../DISCLAIMER_en.md) (Chinese:
[DISCLAIMER.md](../DISCLAIMER.md))**

- This is an **unofficial third-party port**, with no affiliation, partnership, sponsorship or
  endorsement relationship with the upstream authors, Huawei, or any service provider. It provides
  no proxy service, servers, subscriptions or bandwidth.
- **For learning, research and lawful network debugging only.** You must ensure your use complies
  with all applicable laws and regulations in your jurisdiction (telecommunications, cybersecurity,
  data protection, cryptography, export control, …) and with any applicable service terms; **you
  bear all consequences of use**.
- Provided **"AS IS", without warranty of any kind**; to the maximum extent permitted by law, the
  authors and contributors **accept no liability** for any direct or indirect damages arising from
  the use of, or inability to use, this software.
- This port **adds no telemetry**; configuration, subscriptions and logs stay on your device. Your
  proxy server and subscription provider can still observe your network metadata — assess their
  trustworthiness yourself.
- Licensed under upstream **GPL-3.0** (see [LICENSE](../LICENSE)): free to use, modify and
  redistribute, but derivative works must be released under the same license. This repository
  provides **source code only** — no signed packages or certificates.
