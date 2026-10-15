import 'package:bett_box/common/print.dart';
import 'package:bett_box/common/system.dart';
import 'package:code_forge/script.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

Future<bool>? _rustLibReady;

Future<bool> ensureRustLib() => _rustLibReady ??= _initRustLib();

Future<bool> _initRustLib() async {
  try {
    if (system.isOhos) {
      // flutter_rust_bridge 默认加载器不认识 ohos 平台会抛错，
      // 与 libmeta.so 一致按裸名 dlopen（应用 libs 目录在链接器搜索路径内）
      await RustLib.init(
        externalLibrary: ExternalLibrary.open('libcode_forge.so'),
      );
    } else {
      await RustLib.init();
    }
    return true;
  } catch (e) {
    commonPrint.error('Failed to initialize RustLib: $e');
    _rustLibReady = null;
    return false;
  }
}
