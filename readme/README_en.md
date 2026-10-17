<h4 align="right">
  <a href="../README.md">简体中文</a> | <strong>English</strong> | <a href="README_ru.md">Русский</a> | <a href="README_fa.md">فارسی</a> | <a href="README_ja.md">日本語</a> | <a href="README_ko.md">한국어</a>
</h4>

<h1 align="center">⚡ Bettbox</h1>
<p align="center">
  <strong>Another Better Mihomo Client</strong>
</p>

**Bettbox is a cross-platform network traffic routing and DNS debugging tool, deeply built on the powerful Mihomo core. We focus on ultimate user experience, strict privacy and security, and refined feature craftsmanship, dedicated to delivering a more lightweight, smooth, and modern client experience that runs stably over the long term with minimal resource consumption.**

Guided by the design philosophy of **"Better Experience, Out of the box"**, Bettbox deeply taps into system and hardware potential, achieving high frame rates with silky-smooth foreground animations alongside low power consumption and minimal background resource usage. The project has pioneered manual security provenance review by the SignPath Foundation, and the Windows client is signed with an official authoritative OV digital certificate.

[![Latest Release](https://img.shields.io/github/v/release/appshubcc/Bettbox?style=for-the-badge&logo=github&color=238636&label=Release)](https://github.com/appshubcc/Bettbox/releases/latest) [![Core](https://img.shields.io/github/v/release/MetaCubeX/mihomo?style=for-the-badge&logo=go&logoColor=white&color=8A2BE2&label=Mihomo)](https://github.com/MetaCubeX/mihomo/releases/latest)

<p align="center">
  <img src="../snapshots/home.png" alt="Bettbox" />
</p>

---
### ✈️ Telegram Community

[![Telegram Group](https://img.shields.io/badge/Bettbox-Chat-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/appshub_chat) [![Telegram Channel](https://img.shields.io/badge/Bettbox-Channel-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/appshub_channel)

---
## 🚀 Core Features

* **Out-of-the-Box**: Comprehensive permission guidance and smooth TUN / VPN experience with well-tuned presets, ready for optimal use right after installation.
* **Lightweight & Smooth**: Deeply optimized system and rendering pipeline, delivering high FPS, clean and fluid foreground animations, ultra-low mobile power consumption, and minimal desktop resource usage.
* **Security & Trustworthy**: Core closely tracks the upstream Mihomo branch, adheres to the principle of least privilege across platforms, passed SignPath security audit, and comes loaded with an official Windows OV digital certificate.
* **Stability & Fault Tolerance**: Optimized edge-case behavior in extreme multi-platform network environments, featuring built-in dual configuration verification and protection mechanisms for enterprise-grade long-term stability.
* **Architecture Optimization**: Deep native desktop ARM64 support with hardware performance tiering, alongside continuous maintenance of Compatible editions for legacy devices.
* **Smart Daemon**: Supports seamless smart start/stop across platforms, mobile low-power sleep policies, one-click QUIC disabling, and multi-dimensional tray menu quick controls.
* **Visual Settings**: Rich and in-depth visual parameter tuning interface with instant-effect toggles, freeing you from tedious manual configuration editing.
* **Home Widgets**: Multiple beautifully crafted built-in widgets, providing at-a-glance control over real-time network speeds, active connections, and overall operational status on the home screen.
* **Personalization**: Rich color themes, custom icons and titles, along with 30 exquisite speedtest animations.
* **Ecosystem & Extension**: Supports visual UI adaptation for external JS override scripts, and includes a deeply refactored high-performance Code-forge editor.
* **Zero Privacy Risk**: Fully open-source and transparent code, completely ad-free, automated CI/CD pipelines subject to comprehensive audit, and zero background telemetry.
* **Community Driven**: We thoughtfully evaluate community feedback, actively respond to high-quality issues, and evolve together with an active user community.

---
## 🛠️ Installation & Downloads

Please visit the **[[Releases]](https://github.com/appshubcc/Bettbox/releases)** page to download the latest installer suitable for your platform and operating system:

* **Desktop Support**: 
  * **Windows 8.1+:** (x64 / arm64)
  * **Linux Kernel 5.4+:** (x64 / arm64)
  * **macOS 12.0+:** (Intel / Apple Silicon)
* **Mobile & Others**: 
  * **Android 8.0+:** (ARMv8 / ARMv7 / x86_64 / Universal) 
  * **Android TV:** Full large-screen adaptation, optional ARMv7 32-bit version
  * **HarmonyOS NEXT:** Can be used stably with [[ZhuoYiTong]](https://harmonyos.cool/android-app)

**Linux Community Packages:**<br>
* **ArchLinux:** <code>yay -S bettbox-bin</code> or <code>paru -S bettbox-bin</code> (Maintained by [lyj404](https://github.com/lyj404/bettbox-aur))<br>
* **AMD64=v1 (Legacy Hardware Compatibility):** <code>yay -S bettbox-compatible-bin</code> or <code>paru -S bettbox-compatible-bin</code> (Maintained by [VillagerTom](https://github.com/VillagerTom))

---
## 💡 Frequently Asked Questions

1. **System Requirements & Compatibility**:
   - For Android devices, ensure sufficient background execution permissions are granted; system must meet Android 8.0+.
   - For legacy desktop hardware, please choose the corresponding Compatible build based on CPU instruction set architecture.
   - Security: Bettbox is fully open-source and transparent; the code has passed the authoritative SignPath security audit with zero privacy collection.

2. **Desktop Permissions & TUN**:
   - Windows administrator permissions are pre-handled by the installer; daily usage requires no manual re-authorization.
   - When enabling the TUN virtual network adapter on macOS / Linux, enter the correct system password when prompted to complete authorization.
   - For other errors, verify that no conflicting proxy tools are occupying ports in the background, and include debug logs when submitting feedback.

3. **macOS First-Time Installation Guide**:
   - Download and open the `.dmg` installer according to your platform (Intel / Apple Silicon), and drag the Bettbox icon into the Applications folder.
   - **Bypassing System Security Gatekeeper** ([Apple Commercial Developer Certificate is not currently purchased](https://support.apple.com/en-us/102445)):
     - **Recommended**: In "Finder - Applications", **right-click the Bettbox icon and select "Open"**, then click "Open" in the system confirmation prompt.
     - **Alternative**: If blocked, navigate to System "Settings -> Privacy & Security", locate Bettbox, and click "Open Anyway".
   - When enabling TUN mode for the first time, a system password prompt will appear; enter your password to allow the creation of the virtual network interface.

4. **Subscription Import & Troubleshooting**:
   - If import fails, please reset the subscription URL in your service provider's dashboard and try again.
   - If the issue persists, verify the node formats with your provider; if confirmed to be a client issue, feel free to submit an Issue.

---
## 💻 Development, Building & UI Adaptation

Taking Windows build as an example:

* System Requirements: Windows 10 or later
* Dependencies: Git, Visual Studio, Flutter 3.47.x, Golang, Inno Setup, Rust
```bash
* flutter pub get (fetch dependencies)
* dart .\setup.dart windows --arch amd64 --out core (build Core only)
* dart .\setup.dart windows --arch amd64 --out app --compatible (optional compatible build)
* After building, final artifacts are located in the `dist/` directory
```

Custom Script UI Adaptation:

* Bettbox supports graphical UI adaptation for external override scripts. Taking AIsouler's **[Script/Config Repository](https://github.com/AIsouler/MyClash)** as an example, simply add the following declaration at the first line of the script to directly link with built-in visual toggles:
* <code>const Compatible_With_Bettbox = { ruleOptionsEnable: true };</code>
* If the script switches include policy groups and other function switches, you can declare policy group switch names via `policyGroupOptions`; undeclared switches will be automatically grouped under the "⚙️ Other Settings" secondary menu:

```js
const Compatible_With_Bettbox = {
  ruleOptionsEnable: true,
  // Declare switch names belonging to policy groups; must match keys in ruleOptionsEnable exactly
  policyGroupOptions: ['🚀 节点选择', '🛑 广告拦截'],
};
```
* If `policyGroupOptions` is undeclared or names do not match, all toggles will be displayed flat.

---
### 🛩️ Recommended Services
#### IEPL Dedicated Lines  〢  [BBXY](https://www.bbxy01.com/v2/register?code=c09R)  〢  [BaiYueGuang](https://www.sibker.com/register?invite_code=YZq6L5zd)  〢  [Ytoo](https://y-too.net/aff.php?aff=10354)
--------------------------------
#### Budget Direct Lines  〢  [Liangxin Cloud](https://xn--9kqz23b19z.com/#/register?code=VTnrQYAj)  〢  [Chuixue Cloud](https://xn--9kqs1lo79d.com/#/register?code=skKMTab7)  〢  [YiFen](https://xn--4gqx1hgtfdmt.com/#/register?code=AuCiXprV) 
--------------------------------
#### BBXY Exclusive 32% OFF Promo Code: bettbox68 , see: [Details](https://t.me/appshub_channel/381)
--------------------------------

**Review** : ❚ ❚ The links above are primarily for personal use or discussed and recommended within the TG community. They are displayed here solely as AFF links (Note: purchasing third-party services through these links provides a small commission to support the developer), which does not constitute any commitment or guarantee regarding their services. Please evaluate and choose reasonably.

---
### ☕ Sponsoring & Support

**If you find this project helpful, you can also support development through the following methods or by using the [Referral Links](../README.md#%EF%B8%8F-%E6%8E%A8%E8%8D%90%E6%9C%8D%E5%8A%A1):**

* TRON (TRC-20)： <code>TCkTtZfF2WrciZLaJj3e1aqrh3zdTnCkDa</code>
* Bitcoin： <code>bc1qu950cl6035qvllmzk6cfw3l30j2lg3cq9n6g6h</code>

---
## ❤️ Acknowledgments

<table>
  <tr>
    <td>
      <img alt="SignPath" src="https://signpath.org/assets/favicon-50x50.png" />
    </td>
    <td>
    Free code signing on Windows provided by <a href="https://signpath.io">SignPath.io</a>, certificate by <a href="https://signpath.org/">SignPath Foundation</a>
    </td>
  </tr>
</table>

* **[FlClash GUI](https://github.com/chen08209/FlClash)** (This project originated from the excellent open-source project FlClash; tribute to the original author's pioneering exploration and contributions)
* **[Mihomo Core](https://github.com/MetaCubeX/mihomo)** (Powerful and flexible core driver)

Thanks to all [Contributors](https://github.com/appshubcc/Bettbox/graphs/contributors) who have contributed to this project, as well as the following open-source projects for their inspiration and reference:

[Zashboard](https://github.com/Zephyruso/zashboard), [CMFA](https://github.com/MetaCubeX/ClashMetaForAndroid), [Sparkle](https://github.com/xishang0128/sparkle), [SFA](https://github.com/SagerNet/sing-box-for-android), [HUSI](https://github.com/xchacha20-poly1305/husi), [V2rayN](https://github.com/2dust/v2rayN), [Bett-rules](https://github.com/appshubcc/bett-rules)

---
## 📄 License

This project is licensed under the [GPL-3.0 License](../LICENSE).
