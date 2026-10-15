import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bett_box/common/system.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';
import 'package:window_ext/window_ext.dart';

class ProcessIcon {
  static const _size = 128;

  Future<Map<String, String>>? _linuxIndex;

  Future<Uint8List?> get(String path) async {
    if (path.isEmpty) return null;
    try {
      if (system.isMacOS) return await _getMacOS(path);
      if (system.isWindows) return await _getWindows(path);
      if (system.isLinux) return await _getLinux(path);
    } catch (_) {}
    return null;
  }

  Future<Uint8List?> _getMacOS(String path) {
    final index = path.indexOf('.app/');
    final target = index == -1 ? path : path.substring(0, index + 4);
    return windowExtManager.getFileIcon(target, _size);
  }

  Future<Uint8List?> _getWindows(String path) async {
    final bitmap = _readWindowsIcon(path);
    if (bitmap == null) return null;
    final (pixels, width, height) = bitmap;
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.bgra8888,
      completer.complete,
    );
    final image = await completer.future;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  (Uint8List, int, int)? _readWindowsIcon(String path) {
    return using((arena) {
      final pathPtr = path.toNativeUtf16(allocator: arena);
      final iconPtr = arena<Pointer>();
      final count = PrivateExtractIcons(
        PCWSTR(pathPtr),
        0,
        _size,
        _size,
        iconPtr,
        nullptr,
        1,
        0,
      );
      var hIcon = count > 0 && count != 0xFFFFFFFF
          ? HICON(iconPtr.value)
          : HICON(nullptr);
      if (!hIcon.isValid) {
        final info = arena<SHFILEINFO>();
        final res = SHGetFileInfo(
          PCWSTR(pathPtr),
          const FILE_FLAGS_AND_ATTRIBUTES(0),
          info,
          sizeOf<SHFILEINFO>(),
          SHGFI_FLAGS(SHGFI_ICON | SHGFI_LARGEICON),
        );
        if (res != 0) {
          hIcon = info.ref.hIcon;
        }
      }
      if (!hIcon.isValid) return null;
      final iconInfo = arena<ICONINFO>();
      if (!GetIconInfo(hIcon, iconInfo).value) {
        hIcon.close();
        return null;
      }
      final hbmColor = iconInfo.ref.hbmColor;
      final hbmMask = iconInfo.ref.hbmMask;
      final hdc = GetDC(null);
      try {
        if (!hbmColor.isValid) return null;
        final bitmap = arena<BITMAP>();
        if (GetObject(HGDIOBJ(hbmColor), sizeOf<BITMAP>(), bitmap) == 0) {
          return null;
        }
        final width = bitmap.ref.bmWidth;
        final height = bitmap.ref.bmHeight;
        if (width <= 0 || height <= 0) return null;
        final bmi = arena<BITMAPINFO>();
        bmi.ref.bmiHeader
          ..biSize = sizeOf<BITMAPINFOHEADER>()
          ..biWidth = width
          ..biHeight = -height
          ..biPlanes = 1
          ..biBitCount = 32
          ..biCompression = BI_RGB;
        final length = width * height * 4;
        final bits = arena<Uint8>(length);
        final lines = GetDIBits(
          hdc,
          hbmColor,
          0,
          height,
          bits,
          bmi,
          const DIB_USAGE(DIB_RGB_COLORS),
        );
        if (lines == 0) return null;
        final pixels = Uint8List.fromList(bits.asTypedList(length));
        var hasAlpha = false;
        for (var i = 3; i < length; i += 4) {
          if (pixels[i] != 0) {
            hasAlpha = true;
            break;
          }
        }
        for (var i = 0; i < length; i += 4) {
          if (!hasAlpha) {
            pixels[i + 3] = 255;
            continue;
          }
          final alpha = pixels[i + 3];
          if (alpha == 255) continue;
          pixels[i] = pixels[i] * alpha ~/ 255;
          pixels[i + 1] = pixels[i + 1] * alpha ~/ 255;
          pixels[i + 2] = pixels[i + 2] * alpha ~/ 255;
        }
        return (pixels, width, height);
      } finally {
        ReleaseDC(null, hdc);
        if (hbmColor.isValid) hbmColor.close();
        if (hbmMask.isValid) hbmMask.close();
        hIcon.close();
      }
    });
  }

  Future<Uint8List?> _getLinux(String path) async {
    final index = await (_linuxIndex ??= Isolate.run(_buildLinuxIndex));
    final name = p.basename(path).toLowerCase();
    final icon = index[name];
    if (icon == null) return null;
    final file = await Isolate.run(() => _resolveLinuxIcon(icon));
    if (file == null) return null;
    return File(file).readAsBytes();
  }

  static List<String> get _linuxDataDirs {
    final home = Platform.environment['HOME'] ?? '';
    return [
      if (home.isNotEmpty) p.join(home, '.local/share'),
      if (home.isNotEmpty) p.join(home, '.local/share/flatpak/exports/share'),
      '/usr/local/share',
      '/usr/share',
      '/var/lib/flatpak/exports/share',
      '/var/lib/snapd/desktop',
    ];
  }

  static Map<String, String> _buildLinuxIndex() {
    final index = <String, String>{};
    for (final dataDir in _linuxDataDirs) {
      final dir = Directory(p.join(dataDir, 'applications'));
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true, followLinks: true)) {
        if (entity is! File || !entity.path.endsWith('.desktop')) continue;
        String? exec;
        String? icon;
        try {
          for (final line in entity.readAsLinesSync()) {
            if (exec == null && line.startsWith('Exec=')) {
              exec = _parseLinuxExec(line.substring(5));
            } else if (icon == null && line.startsWith('Icon=')) {
              icon = line.substring(5).trim();
            }
            if (exec != null && icon != null) break;
          }
        } catch (_) {
          continue;
        }
        if (icon == null || icon.isEmpty) continue;
        if (exec != null && exec.isNotEmpty) {
          index.putIfAbsent(exec, () => icon!);
        }
        index.putIfAbsent(
          p.basenameWithoutExtension(entity.path).toLowerCase(),
          () => icon!,
        );
      }
    }
    return index;
  }

  static String? _parseLinuxExec(String value) {
    final tokens = value.trim().split(RegExp(r'\s+'));
    for (final token in tokens) {
      final text = token.replaceAll('"', '').replaceAll("'", '');
      if (text.isEmpty || text == 'env' || text.contains('=')) continue;
      return p.basename(text).toLowerCase();
    }
    return null;
  }

  static String? _resolveLinuxIcon(String icon) {
    if (p.isAbsolute(icon)) {
      return icon.toLowerCase().endsWith('.png') && File(icon).existsSync()
          ? icon
          : null;
    }
    const sizes = ['256x256', '128x128', '96x96', '64x64', '48x48'];
    for (final dataDir in _linuxDataDirs) {
      for (final size in sizes) {
        final file = p.join(
          dataDir,
          'icons/hicolor',
          size,
          'apps',
          '$icon.png',
        );
        if (File(file).existsSync()) return file;
      }
    }
    final pixmap = '/usr/share/pixmaps/$icon.png';
    return File(pixmap).existsSync() ? pixmap : null;
  }
}

final processIcon = ProcessIcon();
