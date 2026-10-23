import 'dart:convert';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/pages/toolbox/common.dart';
import 'package:bett_box/pages/toolbox/iperf.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() => AppLocalizations.load(const Locale('zh', 'CN')));

  test('解析服务器地址', () {
    expect(parseIperfAddress('192.168.1.5'), (host: '192.168.1.5', port: 5201));
    expect(parseIperfAddress(' nas.local:5202 '), (
      host: 'nas.local',
      port: 5202,
    ));
    expect(parseIperfAddress('[fe80::1]:6000'), (host: 'fe80::1', port: 6000));
    expect(parseIperfAddress('fe80::1'), (host: 'fe80::1', port: 5201));
    expect(parseIperfAddress('host:0'), isNull);
    expect(parseIperfAddress('a b'), isNull);
    expect(parseIperfAddress(''), isNull);
    expect(formatIperfAddress('fe80::1', 6000), '[fe80::1]:6000');
    expect(formatIperfAddress('10.0.0.2', 5201), '10.0.0.2');
  });

  test('二维码链接可以还原多个地址和设备名', () {
    final link = buildIperfLink(
      hosts: ['192.168.1.5', '10.0.0.8'],
      port: 5202,
      name: '客厅 电视',
    );
    final target = parseIperfLink(link);
    expect(target?.hosts, ['192.168.1.5', '10.0.0.8']);
    expect(target?.port, 5202);
    expect(target?.name, '客厅 电视');
    expect(parseIperfLink('https://example.com'), isNull);
    expect(parseIperfLink('bettbox://iperf?port=5201'), isNull);
  });

  test('解析内核推送的状态', () {
    final state = IperfState.fromJson({
      'role': 'server',
      'session': 3,
      'phase': 'done',
      'peer': '192.168.1.9',
      'protocol': 'udp',
      'direction': 'bidir',
      'parallel': 2,
      'duration': 10,
      'elapsed': 10.02,
      'upload': 0,
      'download': 0,
      'upload-result': {
        'bytes': 1250000,
        'bitrate': 1e6,
        'retransmits': -1,
        'jitter': 0.12,
        'lost': 3,
        'packets': 300,
      },
      'download-result': null,
      'error': '',
    });
    expect(state.role, IperfRole.server);
    expect(state.hasResult, isTrue);
    expect(state.uploadResult?.lossRate, closeTo(0.01, 1e-9));
    expect(state.downloadResult, isNull);
    expect(
      IperfState.fromJson({'protocol': '', 'direction': 'x'}).protocol,
      IperfProtocol.tcp,
    );
    expect(iperfReport(state), contains('3/300'));
  });

  test('TCP 结果带往返延迟', () {
    final state = IperfState.fromJson({
      'phase': 'done',
      'peer': '10.0.0.2',
      'protocol': 'tcp',
      'direction': 'bidir',
      'upload-result': {
        'bytes': 1e9,
        'bitrate': 8e8,
        'retransmits': 4,
        'rtt-min': 8,
        'rtt-mean': 12.5,
        'rtt-max': 20,
      },
      'download-result': {'bytes': 1e9, 'bitrate': 8e8, 'retransmits': 0},
    });
    expect(state.uploadResult?.hasRtt, isTrue);
    expect(state.downloadResult?.hasRtt, isFalse);
    final report = iperfReport(state).split('\n');
    expect(report[2], contains('往返延迟 12.5 ms (8.00–20.0)'));
    expect(report[3], isNot(contains('往返延迟')));
  });

  testWidgets('TCP 结果卡片显示往返延迟', (tester) async {
    Future<void> pump(IperfState state) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: buildIperfPreviewForTesting(state: state),
          ),
        ),
      ),
    );
    const flow = IperfFlow(bytes: 1e9, bitrate: 8e8, retransmits: 0);
    await pump(
      const IperfState(
        phase: IperfPhase.done,
        uploadResult: IperfFlow(
          bytes: 1e9,
          bitrate: 8e8,
          retransmits: 0,
          rttMin: 3,
          rttMean: 42,
          rttMax: 90,
        ),
      ),
    );
    expect(find.text('42.0'), findsOneWidget);
    expect(find.text('42.0 ms  3.00–90.0', findRichText: true), findsOneWidget);
    await pump(const IperfState(phase: IperfPhase.done, uploadResult: flow));
    expect(find.textContaining('往返延迟'), findsNothing);
  });

  testWidgets('数值档位支持自定义输入', (tester) async {
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: const Size(400, 800),
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
    var value = 4;
    Future<void> pump() => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: globalState.navigatorKey,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ToolNumberSegmented(
                presets: const [1, 4, 8],
                value: value,
                title: '并行',
                min: 1,
                max: 128,
                labelOf: (value) => '$value',
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );
    await pump();
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    await tester.tap(find.text('8'));
    await tester.pump();
    expect(value, 8);

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '500');
    await tester.tap(find.text(appLocalizations.submit));
    await tester.pumpAndSettle();
    expect(
      find.text(appLocalizations.numberRangeInvalid(1, 128)),
      findsOneWidget,
    );
    expect(value, 8);

    await tester.enterText(find.byType(TextFormField), '16');
    await tester.tap(find.text(appLocalizations.submit));
    await tester.pumpAndSettle();
    expect(value, 16);
    expect(find.text('16'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsNothing);

    await tester.tap(find.text('16'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.tap(find.text(appLocalizations.submit));
    await tester.pumpAndSettle();
    expect(value, 16);
  });

  test('错误提示', () {
    expect(iperfErrorText('server:25'), contains('25'));
    expect(iperfErrorText('port-in-use', port: 6000), contains('6000'));
    expect(iperfErrorText('busy'), appLocalizations.iperfErrorBusy);
  });

  test('参数随应用设置保存', () {
    const props = AppSettingProps(
      iperfOptions: IperfOptions(
        protocol: IperfProtocol.udp,
        direction: IperfDirection.download,
        parallel: 4,
        serverPort: 6000,
      ),
      localPingOptions: LocalPingOptions(
        protocol: LocalPingProtocol.udp,
        count: 120,
        interval: 250,
        udpPort: 5353,
      ),
    );
    final restored = AppSettingProps.fromJson(
      Map<String, Object?>.from(json.decode(json.encode(props)) as Map),
    );
    expect(restored.iperfOptions, props.iperfOptions);
    expect(restored.localPingOptions, props.localPingOptions);
    expect(AppSettingProps.fromJson({}).iperfOptions, const IperfOptions());
    expect(
      AppSettingProps.fromJson({}).localPingOptions,
      const LocalPingOptions(),
    );
  });
}
