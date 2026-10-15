import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bett_box/clash/interface.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHandler extends ClashHandlerInterface {
  Object? channel = Object();
  bool disconnected = false;
  final sent = <String>[];

  @override
  Future<Object?> sendMessage(String message) async {
    if (disconnected) {
      throw const CoreDisconnectedException();
    }
    sent.add(json.decode(message)['id'] as String);
    return channel;
  }

  void reply(String id, dynamic data) {
    handleResult(
      ActionResult(method: ActionMethod.getMemory, data: data, id: id),
    );
  }

  @override
  Future<bool> preload() async => true;

  @override
  FutureOr<void> reStart() {}

  @override
  FutureOr<bool> destroy() => true;
}

void main() {
  group('ClashHandlerInterface', () {
    test('returns the reply while the channel is alive', () async {
      final handler = _FakeHandler();
      final future = handler.invoke<String>(method: ActionMethod.getMemory);
      await pumpEventQueue();
      handler.reply(handler.sent.single, '42');
      expect(await future, '42');
    });

    test('releases the completer as soon as the reply arrives', () async {
      final handler = _FakeHandler();
      final future = handler.invoke<String>(method: ActionMethod.getMemory);
      await pumpEventQueue();
      handler.reply(handler.sent.single, '42');
      expect(handler.callbackCompleterMap, isEmpty);
      expect(await future, '42');
    });

    test('falls back immediately when its channel is aborted', () async {
      final handler = _FakeHandler();
      final oldChannel = handler.channel!;
      final future = handler.invoke<String>(method: ActionMethod.getMemory);
      await pumpEventQueue();
      final stopwatch = Stopwatch()..start();
      handler.abortRequests(oldChannel);
      expect(await future, '');
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      expect(handler.callbackCompleterMap, isEmpty);
    });

    test('uses the custom onTimeout as fallback', () async {
      final handler = _FakeHandler();
      final oldChannel = handler.channel!;
      final future = handler.invoke<String>(
        method: ActionMethod.getMemory,
        onTimeout: () => 'fallback',
      );
      await pumpEventQueue();
      handler.abortRequests(oldChannel);
      expect(await future, 'fallback');
    });

    test('keeps requests on other channels untouched', () async {
      final handler = _FakeHandler();
      final oldChannel = handler.channel!;
      final oldFuture = handler.invoke<bool>(method: ActionMethod.getMemory);
      await pumpEventQueue();
      handler.channel = Object();
      final newFuture = handler.invoke<String>(method: ActionMethod.getMemory);
      await pumpEventQueue();
      handler.abortRequests(oldChannel);
      expect(await oldFuture, false);
      handler.reply(handler.sent.last, 'alive');
      expect(await newFuture, 'alive');
    });

    test('falls back immediately when the message cannot be sent', () async {
      final handler = _FakeHandler()..disconnected = true;
      final result = await handler.invoke<String>(
        method: ActionMethod.getMemory,
      );
      expect(result, '');
      expect(handler.callbackCompleterMap, isEmpty);
    });

    test('falls back when the peer of a real socket closes', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final client = await Socket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
      );
      final socket = await server.first;
      final handler = _FakeHandler()..channel = socket;
      socket.listen((_) {}, onDone: () => handler.abortRequests(socket));
      final future = handler.invoke<String>(method: ActionMethod.getMemory);
      await pumpEventQueue();
      client.destroy();
      expect(await future.timeout(const Duration(seconds: 2)), '');
      socket.destroy();
      await server.close();
    });

    test('ignores channels for requests that already replied', () async {
      final handler = _FakeHandler();
      final oldChannel = handler.channel!;
      final future = handler.invoke<String>(method: ActionMethod.getMemory);
      await pumpEventQueue();
      handler.reply(handler.sent.single, 'done');
      handler.abortRequests(oldChannel);
      expect(await future, 'done');
    });
  });
}
