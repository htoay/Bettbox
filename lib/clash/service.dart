import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bett_box/clash/interface.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/helper/helper.dart';
import 'package:bett_box/models/core.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/utils/frame_codec.dart';
import 'package:bett_box/utils/platform_check.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class ClashService extends ClashHandlerInterface {
  static ClashService? _instance;

  Completer<ServerSocket> serverCompleter = Completer();

  Completer<Socket> socketCompleter = Completer();

  bool isStarting = false;
  bool _isDestroying = false;

  Process? process;

  Completer<void>? _restartCompleter;

  TransportType _transportType = TransportType.unixSocket;
  String? _socketPath;
  int? _tcpPort;

  factory ClashService() {
    _instance ??= ClashService._internal();
    return _instance!;
  }

  ClashService._internal() {
    _initTransport();
  }

  Future<void> _initTransport() async {
    _transportType = await PlatformChecker.getRecommendedTransport();

    if (_transportType == TransportType.unixSocket) {
      _socketPath = _newSocketPath();
      commonPrint.log('Using Unix Domain Socket: $_socketPath');
    } else {
      _tcpPort = PlatformChecker.getRandomPort();
      commonPrint.log('Using TCP Socket on port: $_tcpPort');
    }

    _initServer();
    reStart();
  }

  String _newSocketPath() {
    final random = Random().nextInt(10000);
    return p.join(Directory.systemTemp.path, 'Bettbox_$random.sock');
  }

  Future<void> _rebindTransport() async {
    try {
      await (await serverCompleter.future).close();
    } catch (_) {}
    serverCompleter = Completer();
    if (_transportType == TransportType.unixSocket) {
      _socketPath = _newSocketPath();
      await _deleteSocketFile();
    }
    _initServer();
  }

  Future<void> _initServer() async {
    runZonedGuarded(
      () async {
        late final ServerSocket server;

        if (_transportType == TransportType.unixSocket) {
          final address = InternetAddress(
            _socketPath!,
            type: InternetAddressType.unix,
          );
          await _deleteSocketFile();
          server = await ServerSocket.bind(address, 0, shared: true);
        } else {
          server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
          _tcpPort = server.port;
          commonPrint.log('TCP Server bound to port: $_tcpPort');
        }

        serverCompleter.complete(server);
        await for (final socket in server) {
          await _destroySocket();
          socketCompleter.complete(socket);

          socket
              .transform(FrameDecoderTransformer())
              .listen(
                (data) {
                  handleResult(ActionResult.fromJson(json.decode(data)));
                },
                onError: (error) {
                  if (_isDestroying || globalState.isExiting) return;
                  commonPrint.error('Frame decode error: $error');
                },
                onDone: () {
                  commonPrint.log('Socket connection closed');
                  abortRequests(socket);
                },
              );
        }
      },
      (error, stack) {
        if (_isDestroying || globalState.isExiting) return;
        commonPrint.error(error.toString());
        if (error is SocketException &&
            !_isDestroying &&
            !globalState.isExiting) {
          globalState.showNotifier(error.toString());
        }
      },
    );
  }

  @override
  Future<void> reStart() async {
    final completer = Completer<void>();
    final previous = _restartCompleter;
    _restartCompleter = completer;

    if (previous != null) {
      await previous.future;
    }

    try {
      // Perform a real restart so every caller is guaranteed to see a fresh
      // core after this call returns. Queued calls will run sequentially.
      await _doRestart();
    } finally {
      if (_restartCompleter == completer) {
        _restartCompleter = null;
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> _doRestart() async {
    isStarting = true;
    _isDestroying = false;

    await _destroySocket();

    if (system.isWindows && !kDebugMode) {
      await helperClient.stopCore().catchError((_) => false);
    }

    process?.kill();
    if (process != null) {
      await process!.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    }
    process = null;

    socketCompleter = Completer();

    final serverSocket = await serverCompleter.future;

    final String arg;
    if (_transportType == TransportType.unixSocket) {
      arg = _socketPath!;
    } else {
      arg = '${serverSocket.port}';
    }

    final homeDirPath = await appPath.homeDirPath;
    final environment = Map<String, String>.from(Platform.environment);
    environment['SAFE_PATHS'] = homeDirPath;

    if (system.isWindows && !kDebugMode) {
      final serviceOk = AppIdentity.isDev
          ? (await windows?.isHelperHealthy() ?? false)
          : (await windows?.registerService() ?? false);
      if (serviceOk) {
        final started = await helperClient.startCore(
          corePath: appPath.corePath,
          arg: arg,
          homeDir: homeDirPath,
        );
        if (started) {
          await _waitForCoreReady();
          isStarting = false;
          if (system.isWindows &&
              globalState.config.appSetting.enableHighPriority) {
            unawaited(
              helperClient
                  .setProcessPriority(
                    '${AppIdentity.coreExecutableName}.exe',
                    true,
                  )
                  .catchError((e) {
                    commonPrint.warn('Failed to set core process priority: $e');
                    return false;
                  }),
            );
          }
          return;
        }
        commonPrint.warn(
          'Helper start core failed, falling back to normal mode',
        );
      }
    }

    if (system.isWindows && AppIdentity.isDev) {
      try {
        await Process.run('taskkill', [
          '/F',
          '/IM',
          '${AppIdentity.coreExecutableName}.exe',
        ]);
      } catch (_) {}
    }

    var connected = await _startCoreDirectly(arg, environment);
    if (!connected) {
      commonPrint.warn('core did not connect, retrying with a fresh transport');
      process?.kill();
      process = null;
      await _rebindTransport();
      final retryArg = _transportType == TransportType.unixSocket
          ? _socketPath!
          : '${(await serverCompleter.future).port}';
      await _startCoreDirectly(retryArg, environment);
    }
    isStarting = false;
    if (system.isWindows &&
        !kDebugMode &&
        globalState.config.appSetting.enableHighPriority) {
      unawaited(
        helperClient
            .setProcessPriority('${AppIdentity.coreExecutableName}.exe', true)
            .catchError((e) {
              commonPrint.warn('Failed to set core process priority: $e');
              return false;
            }),
      );
    }
  }

  Duration get _coreReadyTimeout {
    if (kDebugMode || AppIdentity.isDev) {
      return const Duration(seconds: 15);
    }
    return const Duration(seconds: 6);
  }

  Future<bool> _startCoreDirectly(
    String arg,
    Map<String, String> environment,
  ) async {
    if (system.isLinux && appPath.isAppImage) {
      await appPath.ensureAppImageCoreSynced();
    }
    process = await Process.start(appPath.corePath, [
      arg,
    ], environment: environment);
    process?.stdout.listen((_) {});
    process?.stderr.listen((e) {
      final error = utf8.decode(e);
      if (error.isNotEmpty) commonPrint.error(error);
    });
    return _waitForCoreReady(process);
  }

  Future<bool> _waitForCoreReady([Process? targetProcess]) async {
    final timeout = _coreReadyTimeout;
    try {
      if (targetProcess != null) {
        final result = await Future.any<bool>([
          socketCompleter.future.then((_) => true),
          targetProcess.exitCode.then((code) {
            commonPrint.error(
              'Core process exited prematurely with code: $code',
            );
            return false;
          }),
        ]).timeout(timeout);
        return result;
      }

      await socketCompleter.future.timeout(timeout);
      return true;
    } on TimeoutException {
      commonPrint.error('Core ready timeout after ${timeout.inSeconds}s');
      return false;
    }
  }

  @override
  destroy() async {
    _isDestroying = true;
    final server = await serverCompleter.future;
    await server.close();
    await _deleteSocketFile();
    return true;
  }

  @override
  Future<Socket> sendMessage(String message) async {
    if (_isDestroying || globalState.isExiting) {
      throw const CoreDisconnectedException();
    }
    final socket = await socketCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Core socket connection timed out');
      },
    );
    try {
      final frame = FrameCodec.encode(message);
      socket.add(frame);
      return socket;
    } on SocketException catch (e) {
      if (_isDestroying || globalState.isExiting || isStarting) {
        commonPrint.debug(
          'Ignored message send on closed socket during transition: $e',
        );
        throw const CoreDisconnectedException();
      }
      rethrow;
    } on StateError catch (e) {
      if (_isDestroying || globalState.isExiting || isStarting) {
        commonPrint.debug(
          'Ignored message send on closed socket during transition: $e',
        );
        throw const CoreDisconnectedException();
      }
      rethrow;
    }
  }

  Future<void> _deleteSocketFile() async {
    if (_transportType == TransportType.unixSocket && _socketPath != null) {
      final file = File(_socketPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _destroySocket() async {
    if (socketCompleter.isCompleted) {
      final lastSocket = await socketCompleter.future;
      await lastSocket.close();
      socketCompleter = Completer();
    }
  }

  @override
  shutdown() async {
    _isDestroying = true;
    if (system.isWindows && !kDebugMode) {
      await helperClient.stopCore();
    }
    await _destroySocket();
    process?.kill();
    process = null;
    return true;
  }

  Future<bool> checkCoreHealth({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (_isDestroying || globalState.isExiting || isStarting) return false;
    if (!socketCompleter.isCompleted) return false;
    try {
      final result = await invoke<bool>(
        method: ActionMethod.getIsInit,
        timeout: timeout,
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> preload() async {
    await serverCompleter.future;
    return true;
  }
}

final clashService = system.isDesktop ? ClashService() : null;
