import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class CommonPrint {
  static CommonPrint? _instance;

  CommonPrint._internal();

  factory CommonPrint() {
    _instance ??= CommonPrint._internal();
    return _instance!;
  }

  void log(String? text) => _dispatch(text, LogLevel.info);

  void debug(String? text) => _dispatch(text, LogLevel.debug);

  void warn(String? text) => _dispatch(text, LogLevel.warning);

  void error(String? text) => _dispatch(text, LogLevel.error);

  void _dispatch(String? text, LogLevel level) {
    debugPrint('[APP] $text');
    if (!globalState.isInit) {
      return;
    }
    globalState.appController.addLog(Log.app('$text', level: level));
  }
}

final commonPrint = CommonPrint();
