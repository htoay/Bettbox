import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item.dart';

class RequestsView extends ConsumerStatefulWidget {
  const RequestsView({super.key});

  @override
  ConsumerState<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends ConsumerState<RequestsView>
    with WidgetsBindingObserver {
  late final ScrollController _scrollController;
  late final AppBarSearchState _searchState;
  var _autoScrollToEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchState = AppBarSearchState(onSearch: _onSearch);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.afterRouteTransition(_initRequests);
    });
  }

  bool _isListEqual(List<TrackerInfo> a, List<TrackerInfo> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _initRequests() async {
    if (!mounted) return;
    clashCore.startTrackRequests();
    final history = await clashCore.getRequests();
    if (!mounted) return;
    if (history.isNotEmpty) {
      final current = ref.read(requestsProvider).list;
      if (!_isListEqual(current, history)) {
        ref.read(requestsProvider.notifier).setRequests(history);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      clashCore.stopTrackRequests();
    } else if (state == AppLifecycleState.resumed) {
      _initRequests();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clashCore.stopTrackRequests();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    ref.read(requestsSearchProvider.notifier).state = value;
  }

  void _onKeywordsUpdate(List<String> keywords) {
    final notifier = ref.read(requestsKeywordsProvider.notifier);
    if (listEquals(notifier.state, keywords)) return;
    notifier.state = keywords;
  }

  void _toggleAutoScroll() {
    setState(() {
      _autoScrollToEnd = !_autoScrollToEnd;
    });
  }

  void _cancelAutoScroll() {
    if (_autoScrollToEnd) {
      setState(() {
        _autoScrollToEnd = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(filteredRequestsProvider);
    final hasRequests = requests.isNotEmpty;
    final indexById = {
      for (var i = 0; i < requests.length; i++)
        requests[i].id: requests.length - 1 - i,
    };

    ref.listen<List<TrackerInfo>>(filteredRequestsProvider, (prev, next) {
      if (prev == null || prev.isEmpty || next.isEmpty) return;
      if (!_autoScrollToEnd &&
          _scrollController.hasClients &&
          _scrollController.offset > 0) {
        if (next.last.id != prev.last.id) {
          final prevLastId = prev.last.id;
          final index = next.indexWhere((r) => r.id == prevLastId);
          final addedCount = index == -1
              ? next.length - prev.length
              : next.length - 1 - index;
          if (addedCount > 0) {
            final delta = addedCount * (TrackerInfoItem.height + 1);
            _scrollController.jumpTo(_scrollController.offset + delta);
          }
        }
      }
    });

    return CommonScaffold(
      title: appLocalizations.requests,
      actions: [
        IconButton(
          onPressed: () {
            ref.read(requestsProvider.notifier).clearRequests();
            clashCore.clearRequests();
          },
          tooltip: appLocalizations.clear,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
        IconButton(
          style: _autoScrollToEnd
              ? ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    context.colorScheme.secondaryContainer,
                  ),
                )
              : null,
          onPressed: _toggleAutoScroll,
          tooltip: appLocalizations.autoScroll,
          icon: const Icon(Icons.vertical_align_top_outlined),
        ),
      ],
      searchState: _searchState,
      onKeywordsUpdate: _onKeywordsUpdate,
      body: !hasRequests
          ? NullStatus(
              key: const ValueKey('null'),
              label: appLocalizations.nullTip(appLocalizations.requests),
            )
          : ScrollEdgeRise(
              builder: (_, rise) {
                final slivers = [
                  SliverPadding(
                    padding: EdgeInsets.only(top: 8 + rise, bottom: 16),
                    sliver: SliverFixedExtentList(
                      itemExtent: TrackerInfoItem.height + 1,
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final trackerInfo =
                              requests[requests.length - 1 - index];
                          return TrackerInfoItem(
                            key: ValueKey(trackerInfo.id),
                            index: index,
                            count: requests.length,
                            reversed: false,
                            trackerInfo: trackerInfo,
                            onClickKeyword: (value) {
                              context.commonScaffoldState?.addKeyword(value);
                            },
                            detailTitle: appLocalizations.details,
                          );
                        },
                        childCount: requests.length,
                        findChildIndexCallback: (key) =>
                            indexById[(key as ValueKey<String>).value],
                      ),
                    ),
                  ),
                ];
                return CommonScrollBar(
                  trackVisibility: false,
                  controller: _scrollController,
                  child: ScrollToEndBox(
                    controller: _scrollController,
                    dataSource: requests,
                    enable: _autoScrollToEnd,
                    reverse: false,
                    onCancelToEnd: _cancelAutoScroll,
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
            ),
    );
  }
}
