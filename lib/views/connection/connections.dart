import 'dart:async';

import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'item.dart';

class ConnectionsView extends ConsumerStatefulWidget {
  final bool respectCurrentPage;

  const ConnectionsView({super.key, this.respectCurrentPage = true});

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView>
    with WidgetsBindingObserver, WindowListener {
  late final ScrollController _scrollController;
  Timer? _timer;
  ProviderSubscription? _pageLabelSubscription;
  var _isScrolling = false;
  List<TrackerInfo>? _pendingConnections;

  bool get _isForeground {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    globalState.backgroundMode.addListener(_handleBackgroundModeChanged);
    if (system.isDesktop) {
      windowManager.addListener(this);
    }
    _pageLabelSubscription = ref.listenManual(currentPageLabelProvider, (
      prev,
      next,
    ) {
      if (prev != next) {
        unawaited(_syncUpdateTimer());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.afterRouteTransition(() => unawaited(_syncUpdateTimer()));
    });
  }

  @override
  void dispose() {
    _pageLabelSubscription?.close();
    globalState.backgroundMode.removeListener(_handleBackgroundModeChanged);
    if (system.isDesktop) {
      windowManager.removeListener(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _shouldRunTimer() async {
    if (!mounted) return false;
    if (globalState.backgroundMode.value) {
      return false;
    }
    if (widget.respectCurrentPage &&
        ref.read(currentPageLabelProvider) != PageLabel.connections) {
      return false;
    }
    if (!_isForeground) {
      return false;
    }
    if (system.isDesktop && await window?.isVisible == false) {
      return false;
    }
    return true;
  }

  Future<void> _syncUpdateTimer() async {
    final shouldRun = await _shouldRunTimer();
    if (!mounted) return;
    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) {
      return;
    }
    await _updateConnections();
    if (!mounted || !await _shouldRunTimer()) {
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_updateConnections());
    });
  }

  void _applyPendingConnections() {
    if (_pendingConnections != null) {
      ref.read(connectionsProvider.notifier).state = _pendingConnections!;
      _pendingConnections = null;
    }
  }

  Future<void> _updateConnections() async {
    if (!mounted || !await _shouldRunTimer()) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    final connections = await clashCore.getConnections();
    if (!mounted || !await _shouldRunTimer()) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    final oldConnections = ref.read(connectionsProvider);
    final oldMap = {for (final e in oldConnections) e.id: e};
    var hasChanges = oldConnections.length != connections.length;
    final newConnections = connections.map((item) {
      final oldItem = oldMap[item.id];
      if (oldItem != null) {
        final upSpeed = item.upload - oldItem.upload;
        final downSpeed = item.download - oldItem.download;
        final newItem = item.copyWith(
          uploadSpeed: upSpeed > 0 ? upSpeed : 0,
          downloadSpeed: downSpeed > 0 ? downSpeed : 0,
        );
        if (newItem != oldItem) hasChanges = true;
        return newItem;
      }
      hasChanges = true;
      return item.copyWith(uploadSpeed: 0, downloadSpeed: 0);
    }).toList();
    if (hasChanges) {
      if (_isScrolling) {
        _pendingConnections = newConnections;
      } else {
        ref.read(connectionsProvider.notifier).state = newConnections;
      }
    }
  }

  void _handleBackgroundModeChanged() {
    unawaited(_syncUpdateTimer());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_syncUpdateTimer());
  }

  @override
  void onWindowMinimize() {
    unawaited(_syncUpdateTimer());
  }

  @override
  void onWindowRestore() {
    unawaited(_syncUpdateTimer());
  }

  Future<void> _handleBlockConnection(String id) async {
    clashCore.closeConnection(id);
    _isScrolling = false;
    _pendingConnections = null;
    await _updateConnections();
  }

  void _handleCloseAll() async {
    unawaited(
      clashCore.closeConnections().then<void>(
        (_) {},
        onError: (Object e) =>
            commonPrint.debug('closeConnections ignored: $e'),
      ),
    );
    _isScrolling = false;
    _pendingConnections = null;
    await _updateConnections();
  }

  void _onSearch(String value) {
    ref.read(connectionsSearchProvider.notifier).state = value;
  }

  void _onKeywordsUpdate(List<String> keywords) {
    final notifier = ref.read(connectionsKeywordsProvider.notifier);
    if (listEquals(notifier.state, keywords)) return;
    notifier.state = keywords;
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: appLocalizations.connections,
      onKeywordsUpdate: _onKeywordsUpdate,
      searchState: AppBarSearchState(onSearch: _onSearch),
      actions: [
        IconButton(
          onPressed: _handleCloseAll,
          tooltip: appLocalizations.closeAll,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
        IconButton(
          tooltip: appLocalizations.connectionsSort,
          onPressed: () async {
            final currentSortType = ref.read(connectionsSortProvider);
            final selectedSortType = await globalState
                .showCommonDialog<ConnectionsSortType>(
                  child: OptionsDialog<ConnectionsSortType>(
                    title: appLocalizations.connectionsSort,
                    options: ConnectionsSortType.values
                        .where(
                          (sortType) =>
                              sortType != ConnectionsSortType.creationTime,
                        )
                        .toList(),
                    value: currentSortType,
                    textBuilder: (sortType) {
                      return switch (sortType) {
                        ConnectionsSortType.defaultSort =>
                          appLocalizations.defaultSort,
                        ConnectionsSortType.realTimeSpeed =>
                          appLocalizations.realTimeSpeed,
                        ConnectionsSortType.totalTraffic =>
                          appLocalizations.totalTraffic,
                        ConnectionsSortType.creationTime =>
                          appLocalizations.creationTime,
                      };
                    },
                  ),
                );
            if (selectedSortType != null &&
                selectedSortType != currentSortType) {
              ref.read(connectionsSortProvider.notifier).state =
                  selectedSortType;
            }
          },
          icon: const Icon(Icons.sort),
        ),
      ],
      body: Consumer(
        builder: (_, ref, _) {
          final connections = ref.watch(filteredConnectionsProvider);
          final indexById = {
            for (var i = 0; i < connections.length; i++) connections[i].id: i,
          };
          final sortType = ref.watch(connectionsSortProvider);
          final showSpeed = sortType != ConnectionsSortType.totalTraffic;
          final hasConnections = connections.isNotEmpty;

          if (!hasConnections) {
            return NullStatus(
              label: appLocalizations.nullTip(appLocalizations.connections),
            );
          }

          return ScrollEdgeRise(
            builder: (_, rise) {
              final slivers = [
                SliverPadding(
                  padding: EdgeInsets.only(top: 8 + rise, bottom: 16),
                  sliver: SliverFixedExtentList(
                    itemExtent: TrackerInfoItem.height + 1,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final trackerInfo = connections[index];
                        return TrackerInfoItem(
                          key: ValueKey(trackerInfo.id),
                          index: index,
                          count: connections.length,
                          showSpeed: showSpeed,
                          trackerInfo: trackerInfo,
                          onClickKeyword: (value) {
                            context.commonScaffoldState?.addKeyword(value);
                          },
                          trailing: InkResponse(
                            radius: 12,
                            onTap: () => _handleBlockConnection(trackerInfo.id),
                            child: SizedBox.square(
                              dimension: 40,
                              child: Icon(
                                Icons.block,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          detailTitle: appLocalizations.details,
                        );
                      },
                      childCount: connections.length,
                      findChildIndexCallback: (key) =>
                          indexById[(key as ValueKey<String>).value],
                    ),
                  ),
                ),
              ];
              return CommonScrollBar(
                controller: _scrollController,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _isScrolling = true;
                    } else if (notification is ScrollEndNotification) {
                      _isScrolling = false;
                      _applyPendingConnections();
                    }
                    return false;
                  },
                  child: RouteScrollCacheBuilder(
                    builder: (_, cacheExtent) => CustomScrollView(
                      controller: _scrollController,
                      physics: const NextClampingScrollPhysics(),
                      scrollCacheExtent: cacheExtent,
                      slivers: slivers,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
