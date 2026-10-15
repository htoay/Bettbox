import 'dart:convert';

import 'package:bett_box/clash/core.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final proxies = json.encode({
    'names': ['DIRECT', 'A', 'B', 'Auto', 'Main', 'GLOBAL'],
    'types': ['Direct', 'Shadowsocks', 'Trojan', 'URLTest', 'Selector', 'Selector'],
    'groups': {
      'Auto': {
        'name': 'Auto',
        'type': 'URLTest',
        'now': 'A',
        'all': [1, 2, 'Remote'],
        'testUrl': 'https://example.com/204',
        'hidden': true,
        'icon': 'auto.png',
      },
      'Main': {
        'name': 'Main',
        'type': 'Selector',
        'now': 'Auto',
        'all': [3, 1, 2, 'Missing', 0],
      },
      'GLOBAL': {
        'name': 'GLOBAL',
        'type': 'Selector',
        'now': 'Main',
        'all': [4, 3, 1, 2],
      },
    },
  });

  test('builds groups in GLOBAL order and shares proxy instances', () {
    final groups = buildGroups(proxies, const []);

    expect(groups.map((group) => group.name), ['GLOBAL', 'Main', 'Auto']);
    final main = groups[1];
    expect(main.type, GroupType.Selector);
    expect(main.now, 'Auto');
    expect(main.all.map((proxy) => proxy.name), ['Auto', 'A', 'B', 'DIRECT']);
    expect(main.all.first, const Proxy(name: 'Auto', type: 'URLTest', now: 'A'));
    final auto = groups[2];
    expect(auto.testUrl, 'https://example.com/204');
    expect(auto.hidden, isTrue);
    expect(auto.icon, 'auto.png');
    expect(auto.all.map((proxy) => proxy.name), ['A', 'B']);
    expect(identical(main.all[1], auto.all[0]), isTrue);
  });

  test('merges provider proxies under both names', () {
    final groups = buildGroups(proxies, [
      ExternalProvider.fromJson({
        'name': 'remote',
        'type': 'Proxy',
        'vehicle-type': 'HTTP',
        'count': 1,
        'update-at': DateTime(2026).toIso8601String(),
        'proxies': [
          {'name': 'Remote', 'type': 'Vless'},
        ],
      }),
    ]);

    final auto = groups.firstWhere((group) => group.name == 'Auto');
    expect(auto.all.map((proxy) => proxy.name), ['A', 'B', 'Remote']);
  });

  test('returns nothing for an empty payload', () {
    expect(buildGroups('{}', const []), isEmpty);
    expect(buildGroups('null', const []), isEmpty);
  });
}
