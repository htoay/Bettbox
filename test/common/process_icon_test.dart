import 'dart:io';

import 'package:bett_box/common/process_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS keys collapse helpers into their app bundle', () {
    const chrome = '/Applications/Google Chrome.app';
    expect(
      processIcon.keyOf(
        '$chrome/Contents/Frameworks/Google Chrome Framework.framework/'
        'Helpers/Google Chrome Helper.app/Contents/MacOS/Google Chrome Helper',
      ),
      chrome,
    );
    expect(processIcon.keyOf(chrome), chrome);
    expect(processIcon.keyOf(''), '');
    expect(processIcon.keyOf('/usr/sbin/mDNSResponder'), '');
  }, skip: !Platform.isMacOS);

  test('macOS maps WebKit services to Safari when it is installed', () {
    final key = processIcon.keyOf(
      '/System/Library/Frameworks/WebKit.framework/Versions/A/XPCServices/'
      'com.apple.WebKit.Networking.xpc/Contents/MacOS/com.apple.WebKit.Networking',
    );
    expect(key.endsWith('Safari.app'), isTrue);
  }, skip: !Platform.isMacOS);
}
