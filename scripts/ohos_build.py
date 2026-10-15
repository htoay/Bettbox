"""Bettbox 鸿蒙端构建公共逻辑：SDK 定位、Go Overlay 补丁、TLS 校验。"""

import json
import os
import re
import subprocess
from pathlib import Path

NATIVE_COMPILER = Path('llvm') / 'bin' / 'aarch64-unknown-linux-ohos-clang'


def _sdk_candidates():
    candidates = []
    for variable in ('OHOS_NDK_HOME', 'OHOS_NATIVE_SDK'):
        value = os.environ.get(variable)
        if value:
            candidates.append(Path(value).expanduser())

    base_sdk = os.environ.get('OHOS_BASE_SDK_HOME')
    if base_sdk:
        base = Path(base_sdk).expanduser()
        if base.is_dir():
            # 例如：<你的 OHOS SDK 路径>/23
            for entry in base.iterdir():
                if entry.is_dir() and (entry / 'native' / NATIVE_COMPILER).is_file():
                    candidates.append(entry)
            candidates.append(base)

    root = os.environ.get('OHOS_SDK_HOME')
    if root:
        base = Path(root).expanduser()
        if base.is_dir():
            versions = [
                entry for entry in base.iterdir()
                if entry.is_dir() and entry.name.split('.')[0].isdigit()
            ]
            versions.sort(key=lambda entry: [int(part) for part in entry.name.split('.')], reverse=True)
            candidates.extend(versions)
            candidates.append(base)

    deveco = os.environ.get('DEVECO_SDK_HOME')
    if deveco:
        candidates.append(Path(deveco).expanduser() / 'default' / 'openharmony')
    return candidates


def _local_properties_sdk():
    """从 ohos/local.properties 读取 hwsdk.dir（DevEco/hvigor 的 SDK 配置）。"""
    properties = Path(__file__).resolve().parents[1] / 'ohos' / 'local.properties'
    if not properties.is_file():
        return None
    for line in properties.read_text(encoding='utf-8').splitlines():
        key, _, value = line.partition('=')
        if key.strip() in ('hwsdk.dir', 'sdk.dir') and value.strip():
            candidate = Path(value.strip()).expanduser()
            if candidate.is_dir():
                return candidate
    return None


def find_sdk():
    """定位鸿蒙 SDK 根目录，同时提供 native 与 toolchains。"""
    candidates = list(_sdk_candidates())
    local = _local_properties_sdk()
    if local is not None:
        # local.properties 里通常是 sdk 根目录（含 default/openharmony 或版本子目录）
        candidates.append(local)
        if (local / 'default' / 'openharmony').is_dir():
            candidates.append(local / 'default' / 'openharmony')
        for entry in sorted(local.glob('*')):
            if entry.is_dir():
                candidates.append(entry)
    for candidate in candidates:
        if (candidate / 'native' / NATIVE_COMPILER).is_file():
            return candidate
        if (candidate / NATIVE_COMPILER).is_file():
            return candidate.parent
    raise SystemExit(
        '未找到鸿蒙 SDK，请设置 OHOS_BASE_SDK_HOME、OHOS_SDK_HOME 或 DEVECO_SDK_HOME，'
        '或在 ohos/local.properties 中配置 hwsdk.dir。'
    )


def find_native_sdk():
    sdk = find_sdk()
    if (sdk / 'native').is_dir():
        return sdk / 'native'
    return sdk


def go_overlay(root, goroot):
    """生成鸿蒙 Go 运行时适配：c-shared 在 musl 下改用固定 TLS 槽位存放 g。

    Go 的 linux/arm64 运行时把 g 的 TLS 偏移放在 runtime.tls_g，并用
    initial-exec 模型访问；musl 拒绝 dlopen 这样的库。musl/aarch64 规定
    TP 上方 16 字节为空档（GAP_ABOVE_TP），因此这里把 runtime.tls_g 改成
    普通全局变量（内容固定为 8，即 TP+8），和 Android 使用固定槽位一样。
    另外 musl 调用 .init_array 时不传 argc/argv，需要给 runtime 一个合法的
    空 argv 缓冲，让 sysargs 走 /proc/self/auxv 兜底。
    """
    overlay_directory = root / 'core' / 'build' / 'ohos-go-overlay'
    files = {}

    def write(relative, content):
        destination = overlay_directory / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(content, encoding='utf-8')
        files[str(Path(goroot) / relative)] = str(destination)

    tls_asm = (Path(goroot) / 'src' / 'runtime' / 'tls_arm64.s').read_text(encoding='utf-8')
    if (tls_asm.count('MOVD' + chr(9) + 'runtime·tls_g(SB), R27') != 2
            or tls_asm.count('GLOBL runtime·tls_g+0(SB), TLSBSS, $8') != 1):
        raise SystemExit('Go 的 src/runtime/tls_arm64.s 与预期不一致，无法生成鸿蒙 TLS 适配。')
    tls_asm = tls_asm.replace('runtime·tls_g', 'runtime·ohos_tls_g_offset')
    start = tls_asm.index('#ifdef TLSG_IS_VARIABLE')
    tail = tls_asm.index('GLOBL runtime·ohos_tls_g_offset+0(SB), TLSBSS, $8')
    end = tls_asm.index(chr(10) + '#endif' + chr(10), tail) + len(chr(10) + '#endif' + chr(10))
    replacement = (
        '// 鸿蒙（musl/aarch64）：TP 上方 16 字节为保留空档（GAP_ABOVE_TP），'
        '使用 TP+8 作为 g 的槽位。' + chr(10)
        + 'DATA runtime·ohos_tls_g_offset+0(SB)/8, $8' + chr(10)
        + 'GLOBL runtime·ohos_tls_g_offset+0(SB), NOPTR, $8' + chr(10)
    )
    tls_asm = tls_asm[:start] + replacement + tls_asm[end:]
    if tls_asm.count('$8' + chr(10) + 'GLOBL runtime·ohos_tls_g_offset') != 1:
        raise SystemExit('鸿蒙 TLS 槽位定义生成失败。')
    write('src/runtime/tls_arm64.s', tls_asm)

    settls = (Path(goroot) / 'src' / 'runtime' / 'asm_arm64.s').read_text(encoding='utf-8')
    if settls.count('MOVW' + chr(9) + 'R0, 8(RSP) // argc') != 1 or settls.count('MOVD' + chr(9) + 'R1, 16(RSP) // argv') != 1:
        raise SystemExit('Go 的 src/runtime/asm_arm64.s 缺少 rt0_go 参数入口，无法生成鸿蒙启动适配。')
    # musl 调用 .init_array 时不传参数，R0/R1 是垃圾值。给一个全零 argv 缓冲，
    # sysargs 会走 /proc/self/auxv 兜底读取页大小和硬件能力。
    settls = settls.replace(
        'MOVW' + chr(9) + 'R0, 8(RSP) // argc',
        'MOVW' + chr(9) + 'ZR, 8(RSP) // argc（musl 不向 init_array 传参）',
        1,
    ).replace(
        'MOVD' + chr(9) + 'R1, 16(RSP) // argv',
        'MOVD' + chr(9) + '$runtime·ohos_empty_argv(SB), R1 // argv（全零缓冲，供 sysargs 兜底）'
        + chr(10) + chr(9) + 'MOVD' + chr(9) + 'R1, 16(RSP)',
        1,
    )
    settls = settls.replace(
        'GLOBL _rt0_arm64_lib_argv<>(SB),NOPTR, $8',
        'GLOBL _rt0_arm64_lib_argv<>(SB),NOPTR, $8' + chr(10)
        + 'GLOBL runtime·ohos_empty_argv+0(SB), NOPTR, $24',
        1,
    )
    if 'ohos_empty_argv' not in settls:
        raise SystemExit('Go 的 src/runtime/asm_arm64.s 缺少 argc/argv 定义，无法生成鸿蒙启动适配。')
    write('src/runtime/asm_arm64.s', settls)

    # 根证书：鸿蒙（GOOS=linux）不在 Go 的证书搜索路径里，crypto/x509 会拿到空池，
    # 导致核心自身的 HTTPS 全部校验失败（DoH 解析 proxy-server-nameserver、
    # rule-providers 拉取、带校验的 TLS 节点）。这里补一个同包 init，
    # 把鸿蒙/Android 风格的证书目录追加进 crypto/x509 的搜索列表。
    # 文件名 zz_ 前缀保证 init 顺序在 root_linux.go 之后。
    write('src/crypto/x509/zz_ohos_roots.go', '''package x509

// 鸿蒙（OpenHarmony/HarmonyOS）的 CA 库布局与 Android 一致，
// 但 Go 只会在 GOOS=android 时搜索它们；鸿蒙构建使用 GOOS=linux，
// 因此这里显式追加，缺失的路径会被自动跳过。
func init() {
	certDirectories = append(certDirectories,
		"/system/etc/security/cacerts",    // 鸿蒙/Android 系统根证书
		"/data/misc/keychain/certs-added", // 用户安装的根证书
		"/data/service/el1/public/security/cacerts", // 鸿蒙 EL1 公共证书目录
	)
	certFiles = append(certFiles,
		"/system/etc/ssl/certs/cacert.pem",
		"/etc/ssl/certs/cacert.pem",
	)
}
''')

    manifest = overlay_directory / 'overlay.json'
    manifest.write_text(json.dumps({'Replace': files}, indent=2) + chr(10), encoding='utf-8')
    return manifest
