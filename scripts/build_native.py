#!/usr/bin/env python3
"""Bettbox 鸿蒙原生核心交叉编译脚本 (Go Mihomo Core + Rust code_forge)."""

import argparse
import os
import shutil
import subprocess
from pathlib import Path

from ohos_build import find_native_sdk, go_overlay

root = Path(__file__).resolve().parents[1]

parser = argparse.ArgumentParser(description='编译 Bettbox 鸿蒙原生库')
parser.add_argument('--rust-only', action='store_true', help='仅编译 Rust code_forge')
parser.add_argument('--go-only', action='store_true', help='仅编译 Go Mihomo 核心')
parser.add_argument('--output-dir', type=Path, help='输出目录，默认 ohos/entry/libs/arm64-v8a')
options = parser.parse_args()

out_dir = options.output_dir or (root / 'ohos' / 'entry' / 'libs' / 'arm64-v8a')
out_dir.mkdir(parents=True, exist_ok=True)

ndk = find_native_sdk()
clang = ndk / 'llvm' / 'bin' / 'aarch64-unknown-linux-ohos-clang'
readelf = ndk / 'llvm' / 'bin' / 'llvm-readelf'
strip = ndk / 'llvm' / 'bin' / 'llvm-strip'

if not clang.is_file():
    raise SystemExit(f'缺少鸿蒙 NDK 编译器：{clang}')


def rust_ohos_env(sdk=None) -> dict:
    """为 OHOS 目标的 Rust 交叉编译准备环境变量（链接器/系统根）。

    find_native_sdk() 可能返回 SDK 根或其 native 子目录，这里两种布局都探测，
    避免把本机路径写进仓库。
    """
    import os as _os
    env = dict(_os.environ)
    if sdk is None:
        try:
            sdk = find_native_sdk()
        except Exception:
            sdk = None
    bases = []
    if sdk:
        bases = [sdk, Path(sdk) / 'native']
    llvm = None
    sysroot = None
    for b in bases:
        cand = Path(b) / 'llvm' / 'bin' / 'aarch64-unknown-linux-ohos-clang'
        if llvm is None and cand.exists():
            llvm = cand
        cand_sys = Path(b) / 'sysroot'
        if sysroot is None and cand_sys.exists():
            sysroot = cand_sys
    if llvm is None or sysroot is None:
        return env
    env["CARGO_TARGET_AARCH64_UNKNOWN_LINUX_OHOS_LINKER"] = str(llvm)
    env["CC_aarch64_unknown_linux_ohos"] = str(llvm)
    env["CFLAGS_aarch64_unknown_linux_ohos"] = f"--target=aarch64-linux-ohos --sysroot={sysroot}"
    rustflags = (f"-C link-arg=--target=aarch64-linux-ohos "
                 f"-C link-arg=--sysroot={sysroot} "
                 f"-C link-arg=-Wl,-z,max-page-size=16384")
    env["RUSTFLAGS"] = (env.get("RUSTFLAGS", "") + " " + rustflags).strip()

    # rquickjs 在鸿蒙 target 下必须开启 bindgen（见 plugins/code_forge/rust/Cargo.toml：
    # `cfg(target_env = "ohos")`），bindgen 需要 NDK 自带的 libclang 与目标 sysroot 头文件，
    # 否则 rquickjs-sys 会去 include 不存在的 bindings/aarch64-unknown-linux-ohos.rs 而编译失败。
    # 这里从已探测到的 NDK 布局推导，避免在仓库里写死本机路径。
    libclang_dir = Path(llvm).parent.parent / 'lib'
    if libclang_dir.is_dir():
        env["LIBCLANG_PATH"] = str(libclang_dir)
    env["BINDGEN_EXTRA_CLANG_ARGS"] = f"--sysroot={sysroot}"
    return env


def build_rust():
    # 交叉编译所需的链接器/系统根（仓库里不再写死本机路径）
    os.environ.update(rust_ohos_env())
    print('=== [1/2] 编译 Rust code_forge 核心 ===', flush=True)
    rust_dir = root / 'plugins' / 'code_forge' / 'rust'
    env = os.environ.copy()
    env['CC_aarch64_unknown_linux_ohos'] = str(clang)
    env['CFLAGS_aarch64_unknown_linux_ohos'] = f'--target=aarch64-linux-ohos --sysroot={ndk / "sysroot"}'
    subprocess.run(
        ['cargo', 'build', '--target', 'aarch64-unknown-linux-ohos', '--release'],
        cwd=rust_dir,
        env=env,
        check=True,
    )
    src_so = rust_dir / 'target' / 'aarch64-unknown-linux-ohos' / 'release' / 'libcode_forge.so'
    dst_so = out_dir / 'libcode_forge.so'
    shutil.copy2(src_so, dst_so)
    if strip.is_file():
        subprocess.run([str(strip), '--strip-unneeded', str(dst_so)], check=True)
    print(f'已生成 Rust 核心：{dst_so} ({dst_so.stat().st_size // 1024} KB)', flush=True)


def build_go():
    print('=== [2/2] 编译 Go Mihomo 核心 (libmeta.so) ===', flush=True)
    go = shutil.which('go')
    if not go:
        raise SystemExit('未找到 Go 工具链，请安装 Go 1.20 或更高版本。')

    env = os.environ.copy()
    env.setdefault('GOPROXY', 'https://goproxy.cn,direct')
    env.setdefault('GOSUMDB', 'off')
    goroot = subprocess.check_output([go, 'env', 'GOROOT'], cwd=root / 'core', env=env, text=True).strip()

    overlay = go_overlay(root, goroot)
    flags = f'--target=aarch64-linux-ohos --sysroot={ndk / "sysroot"}'

    build_env = env.copy()
    build_env.update(
        GOOS='linux',
        GOARCH='arm64',
        CGO_ENABLED='1',
        CC=str(clang),
        CGO_CFLAGS=flags,
        CGO_LDFLAGS=f'{flags} -Wl,-z,max-page-size=16384',
    )

    dst_so = out_dir / 'libmeta.so'

    print(f'正在使用 Go overlay: {overlay}', flush=True)
    subprocess.run(
        [
            go,
            'build',
            '-trimpath',
            '-buildmode=c-shared',
            '-tags=with_gvisor,ohos',
            '-ldflags=-w -s -extldflags "-Wl,-z,max-page-size=16384"',
            f'-overlay={overlay}',
            '-o',
            str(dst_so),
            '.',
        ],
        cwd=root / 'core',
        env=build_env,
        check=True,
    )

    if readelf.is_file():
        relocations = subprocess.check_output([str(readelf), '-r', str(dst_so)], text=True)
        if 'R_AARCH64_TLS_TPREL' in relocations:
            raise SystemExit('鸿蒙核心仍包含 initial-exec TLS 重定位，musl 无法 dlopen；请检查 Go overlay 是否生效。')
        print('TLS 重定位检查通过，无 R_AARCH64_TLS_TPREL 违规符号。', flush=True)

    if strip.is_file():
        subprocess.run([str(strip), '--strip-unneeded', str(dst_so)], check=True)

    print(f'已生成 Go 核心：{dst_so} ({dst_so.stat().st_size // 1024} KB)', flush=True)


if not options.go_only:
    build_rust()

if not options.rust_only:
    build_go()

print('=== 鸿蒙原生核心编译全部完成 ===', flush=True)
