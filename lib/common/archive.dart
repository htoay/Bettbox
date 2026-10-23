import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart';

extension ArchiveExt on Archive {
  Future<void> addDirectoryToArchive(String dirPath, String parentPath) async {
    final dir = Directory(dirPath);
    final entities = await dir.list(recursive: false).toList();
    for (final entity in entities) {
      final relativePath = relative(
        entity.path,
        from: parentPath,
      ).replaceAll('\\', '/');
      if (entity is File) {
        final data = await entity.readAsBytes();
        final archiveFile = ArchiveFile(relativePath, data.length, data);
        addFile(archiveFile);
      } else if (entity is Directory) {
        await addDirectoryToArchive(entity.path, parentPath);
      }
    }
  }

  void add<T>(String name, T raw) {
    final data = json.encode(raw);
    addFile(ArchiveFile(name, data.length, utf8.encode(data)));
  }
}

Future<void> restoreBackupFiles(
  Iterable<ArchiveFile> profiles,
  String homeDirPath,
) async {
  final canonicalHome = canonicalize(homeDirPath);
  for (final profile in profiles) {
    final normalizedName = profile.name.replaceAll('\\', '/');
    if (!profile.isFile || normalizedName.endsWith('/')) continue;
    final targetPath = canonicalize(join(homeDirPath, normalizedName));
    if (!isWithin(canonicalHome, targetPath)) continue;
    final file = File(targetPath);
    await file.create(recursive: true);
    await file.writeAsBytes(profile.content);
  }
}

class BackupPasswordException implements Exception {
  final bool wrong;

  const BackupPasswordException({required this.wrong});
}

bool isValidBackupPassword(String password) {
  return password.codeUnits.every((unit) => unit >= 0x20 && unit <= 0x7e);
}

({Archive archive, bool encrypted}) decodeBackupArchive(
  InputStream input,
  String? password,
) {
  final decoder = ZipDecoder();
  final archive = decoder.decodeStream(input, password: password);
  final encrypted = decoder.directory.fileHeaders.any(
    (header) => header.generalPurposeBitFlag & 0x1 != 0,
  );
  if (encrypted && password == null) {
    throw const BackupPasswordException(wrong: false);
  }
  final result = Archive();
  for (final file in archive.files) {
    if (!file.isFile) continue;
    try {
      result.addFile(ArchiveFile.bytes(file.name, file.content));
    } catch (_) {
      if (encrypted) throw const BackupPasswordException(wrong: true);
      rethrow;
    }
  }
  return (archive: result, encrypted: encrypted);
}
