import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/plugins/app.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Picker {
  Future<List<PlatformFile>?> pickerFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    if (system.isOhos) {
      return _pickerFilesOhos(
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,
      );
    }
    final useCustom =
        !system.isMobile &&
        allowedExtensions != null &&
        allowedExtensions.isNotEmpty;
    if (system.isMacOS) {
      await FilePicker.skipEntitlementsChecks();
    }
    if (allowMultiple) {
      final files = await FilePicker.pickFiles(
        allowedExtensions: useCustom ? allowedExtensions : null,
        type: useCustom ? FileType.custom : FileType.any,
        initialDirectory: await appPath.downloadDirPath,
      );
      return files.isEmpty ? null : files;
    } else {
      final file = await FilePicker.pickFile(
        allowedExtensions: useCustom ? allowedExtensions : null,
        type: useCustom ? FileType.custom : FileType.any,
        initialDirectory: await appPath.downloadDirPath,
      );
      return file != null ? [file] : null;
    }
  }

  /// 鸿蒙端没有 file_picker 实现：走系统文件选择器（AppPlugin.pickFiles），
  /// 原生侧已把选中的文件复制到缓存目录，这里读取字节构造 PlatformFile。
  /// 上游 v1.19.5 的 file_picker 新 API 去掉了 withData 参数，鸿蒙侧一律带上字节。
  Future<List<PlatformFile>?> _pickerFilesOhos({
    required bool allowMultiple,
    List<String>? allowedExtensions,
  }) async {
    final picked = await app.pickFiles(
      allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
    );
    if (picked.isEmpty) return null;
    final files = <PlatformFile>[];
    for (final item in picked) {
      var size = 0;
      Uint8List? bytes;
      try {
        final file = File(item.path);
        size = await file.length();
        bytes = await file.readAsBytes();
      } catch (e) {
        commonPrint.log('Read picked file failed: $e');
      }
      files.add(
        _OhosPlatformFile(
          name: item.name,
          path: item.path,
          size: size,
          bytes: bytes,
        ),
      );
    }
    return files.isEmpty ? null : files;
  }

  Future<PlatformFile?> pickerFile({List<String>? allowedExtensions}) async {
    final files = await pickerFiles(
      allowMultiple: false,
      allowedExtensions: allowedExtensions,
    );
    return files != null && files.isNotEmpty ? files.first : null;
  }

  Future<String?> saveFile(
    String fileName,
    Uint8List bytes, {
    List<String>? allowedExtensions,
  }) async {
    var name = fileName;
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      final hasExt = allowedExtensions.any((ext) => name.endsWith('.$ext'));
      if (!hasExt) {
        name = '$name.${allowedExtensions.first}';
      }
    }
    // 鸿蒙没有 file_picker 实现，改走原生保存对话框（AppPlugin.saveFile）
    if (system.isOhos) {
      return app.saveFile(name, bytes);
    }
    if (system.isMacOS) {
      await FilePicker.skipEntitlementsChecks();
    }
    final uri = await FilePicker.saveFile(
      fileName: name,
      initialDirectory: await appPath.downloadDirPath,
      bytes: bytes,
    );
    if (uri == null) return null;
    if (uri.scheme != 'file') return uri.path;

    final path = uri.toFilePath();
    if (allowedExtensions == null || allowedExtensions.isEmpty) return path;
    if (allowedExtensions.any((ext) => path.endsWith('.$ext'))) return path;
    final savePath = '$path.${allowedExtensions.first}';
    await File(path).rename(savePath);
    return savePath;
  }

  Future<String?> pickerConfigQRCode() async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile == null) {
      return null;
    }
    return decodeProfileUrlFromQrImage(xFile.path);
  }

  Future<String?> decodeProfileUrlFromQrImage(String path) async {
    final result = await _decodeQrCodeImage(path);
    if (result == null || !result.isUrl) {
      throw appLocalizations.pleaseUploadValidQrcode;
    }
    return result;
  }

  Future<String?> _decodeQrCodeImage(String path) async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      try {
        final capture = await MobileScannerController().analyzeImage(
          path,
          formats: const [BarcodeFormat.qrCode],
        );
        final barcodes = capture?.barcodes;
        final result = barcodes == null || barcodes.isEmpty
            ? null
            : barcodes.first.rawValue;
        if (result != null && result.isNotEmpty) {
          return result;
        }
      } catch (e) {
        commonPrint.warn('Native qr decode failed: $e');
      }
    }
    return qrReader.decodeFile(path);
  }
}

/// file_picker 13 的 `PlatformFile` 是 `abstract base class`，没有公开构造器，
/// 鸿蒙端又没有 file_picker 实现，所以按 AndroidPlatformFile 的最小等价方式自行实现：
/// 只需要能回答 name / uri / 长度 / 字节流，其余交给调用方现有的 readAsBytes()/xFile。
base class _OhosPlatformFile extends PlatformFile {
  _OhosPlatformFile({
    required this.name,
    required String path,
    int? size,
    Uint8List? bytes,
  }) : uri = Uri.file(path),
       _size = size,
       _bytes = bytes;

  @override
  final String name;

  @override
  final Uri uri;

  final int? _size;
  final Uint8List? _bytes;

  @override
  XFile get xFile => XFile(uri.toFilePath(), name: name);

  @override
  int? lengthSync() => _size;

  @override
  Future<int?> length() async {
    final size = _size;
    if (size != null && size > 0) return size;
    try {
      return await xFile.length();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List> readAsBytes() async {
    final bytes = _bytes;
    if (bytes != null) return bytes;
    return xFile.readAsBytes();
  }

  @override
  Stream<Uint8List> readAsByteStream() => xFile.openRead();
}

final picker = Picker();
