import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/pages/toolbox/nat_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a Go stun state', () {
    final state = StunTestState.fromJson({
      'phase': 'done',
      'nat-type': 'port-restricted',
      'mapping': 'independent',
      'filtering': 'address-port',
      'rfc5780': true,
      'external-ip': '1.2.3.4',
      'external-port': 6584,
      'port-preserved': 0,
      'latency': 23.5,
      'packet-loss': 0.125,
      'outbound': {
        'chains': ['Proxy', 'HK'],
      },
    });
    expect(state.natType, NatType.portRestricted);
    expect(state.hasResult, isTrue);
    expect(state.outbound?.chains.last, 'HK');
    expect(natTypeBadge(state.natType), 'NAT3');
  });

  test('unknown values fall back safely', () {
    final state = StunTestState.fromJson({'error': 'unsupported'});
    expect(state.natType, NatType.unknown);
    expect(state.isFinished, isTrue);
    expect(state.hasResult, isFalse);
  });

  test('validates stun servers', () {
    expect(isValidStunServer('stun.example.com:3478'), isTrue);
    expect(isValidStunServer('stun.example.com'), isFalse);
    expect(isValidStunServer('stun.example.com:70000'), isFalse);
    expect(isValidStunServer('a b:3478'), isFalse);
  });
}
