import 'dart:io';

import 'package:flutter_app_packager/src/api/make_config.dart';

class MakeResult {
  MakeResult(
    this.config, {
    this.duration,
    List<FileSystemEntity>? artifacts,
  }) : artifacts = artifacts ?? config.outputArtifacts;

  final MakeConfig config;
  final List<FileSystemEntity> artifacts;
  final Duration? duration;

  Map<String, dynamic> toJson() {
    return {
      'config': config.toJson(),
      'artifacts': artifacts
          .map(
            (e) => {
              'type': e is File ? 'file' : 'directory',
              'path': e.path,
            },
          )
          .toList(),
      'duration': duration,
    }..removeWhere((key, value) => value == null);
  }
}

abstract class MakeResultResolver {
  MakeResult resolve(
    MakeConfig config, {
    List<FileSystemEntity>? artifacts,
  });
}

class DefaultMakeResultResolver extends MakeResultResolver {
  @override
  MakeResult resolve(
    MakeConfig config, {
    List<FileSystemEntity>? artifacts,
  }) {
    MakeResult makeResult = MakeResult(config, artifacts: artifacts);
    return makeResult;
  }
}
