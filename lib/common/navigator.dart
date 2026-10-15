import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/app.dart';
import 'package:bett_box/state.dart';
import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialPageRoute;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class BaseNavigator {
  static Future<T?> push<T>(
    BuildContext context,
    Widget child, {
    bool maintainState = true,
  }) async {
    if (globalState.appState.viewMode != ViewMode.mobile) {
      return await Navigator.of(context).push<T>(
        CommonDesktopRoute(
          builder: (context) => child,
          maintainState: maintainState,
        ),
      );
    }
    return await Navigator.of(context).push<T>(
      _CleanCupertinoPageRoute(
        builder: (context) => child,
        maintainState: maintainState,
      ),
    );
  }
}

class _CleanCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  _CleanCupertinoPageRoute({
    required super.builder,
    super.title,
    super.settings,
    super.fullscreenDialog,
    super.maintainState,
  });

  @override
  Color? get barrierColor => null;

  static final DelegatedTransitionBuilder? _hostDelegatedTransition = () {
    final route = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );
    final transition = route.delegatedTransition;
    route.dispose();
    return transition;
  }();

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _hostDelegatedTransition;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    );
  }
}

class CommonDesktopRoute<T> extends PageRoute<T> {
  final Widget Function(BuildContext context) builder;

  CommonDesktopRoute({required this.builder, this.maintainState = true});

  @override
  final bool maintainState;

  static final _enterTween = CurveTween(curve: const Interval(0.2, 1));
  static final _exitTween = Tween<double>(
    begin: 1,
    end: 0,
  ).chain(CurveTween(curve: const Interval(0, 0.4)));

  static Widget? _buildExitTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return FadeTransition(
      opacity: _exitTween.animate(secondaryAnimation),
      child: child,
    );
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _buildExitTransition;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = builder(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: FadeTransition(
        opacity: _enterTween.animate(animation),
        child: result,
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: _exitTween.animate(secondaryAnimation),
      child: child,
    );
  }

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => Duration(milliseconds: 200);
}

class RouteIdleObserver extends NavigatorObserver {
  static const _settleDuration = Duration(milliseconds: 250);
  static const _busyTimeout = Duration(seconds: 3);

  final busy = ValueNotifier<bool>(false);
  final _clock = Stopwatch()..start();
  Duration _changedAt = Duration.zero;
  int _activeTransitions = 0;
  bool _gestureActive = false;

  bool get isSettled {
    final elapsed = _clock.elapsed - _changedAt;
    return elapsed >= (busy.value ? _busyTimeout : _settleDuration);
  }

  void _update() {
    _changedAt = _clock.elapsed;
    busy.value = _gestureActive || _activeTransitions > 0;
  }

  void _track(Route<dynamic>? route) {
    final animation = route is ModalRoute ? route.animation : null;
    if (animation == null ||
        animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed) {
      _update();
      return;
    }
    _activeTransitions++;
    _update();
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      if (route is ModalRoute && route.offstage) return;
      animation.removeStatusListener(listener);
      _activeTransitions--;
      _update();
    }

    animation.addStatusListener(listener);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _gestureActive = true;
    _update();
  }

  @override
  void didStopUserGesture() {
    _gestureActive = false;
    _update();
  }

  Future<void> whenIdle({Duration timeout = const Duration(seconds: 3)}) async {
    if (!busy.value) return;
    final completer = Completer<void>();
    void listener() {
      if (!busy.value && !completer.isCompleted) completer.complete();
    }

    busy.addListener(listener);
    await completer.future.timeout(timeout, onTimeout: () {});
    busy.removeListener(listener);
  }
}

final routeIdleObserver = RouteIdleObserver();

extension FocusNodeIdleExt on FocusNode {
  Future<void> requestFocusWhenIdle() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    await routeIdleObserver.whenIdle();
    await binding.endOfFrame;
    if (context == null || !canRequestFocus) return;
    requestFocus();
  }
}
