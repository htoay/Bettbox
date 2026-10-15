import 'package:bett_box/common/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('patchYamlConfig', () {
    test('returns content without tabs unchanged', () {
      const content = 'proxies:\n  - name: a\n    short-id: 0123abcd\n';

      expect(identical(utils.patchYamlConfig(content), content), isTrue);
    });

    test('replaces tabs inside leading whitespace only', () {
      const content = 'proxies:\n\t- name: "a\tb"\n \t  server: x\n';

      expect(
        utils.patchYamlConfig(content),
        'proxies:\n  - name: "a\tb"\n     server: x\n',
      );
    });
  });

  group('patchValidateConfig', () {
    test('forces geodata-mode to false', () {
      expect(
        utils.patchValidateConfig('geodata-mode: true\nmode: rule\n'),
        'geodata-mode: false\nmode: rule\n',
      );
    });
  });
}
