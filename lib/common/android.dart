import 'package:bett_box/plugins/app.dart';
import 'package:bett_box/state.dart';

import 'system.dart';

class Android {
  Future<void> init() async {
    app.onExit = () async {
      await globalState.appController.savePreferences();
    };
  }
}

final android = system.isAndroid ? Android() : null;
