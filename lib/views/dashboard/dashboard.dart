import 'dart:async';
import 'dart:math' as math;

import 'package:bett_box/state.dart';
import 'package:flutter/foundation.dart';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef _IsEditWidgetBuilder = Widget Function(bool isEdit);

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final key = GlobalKey<SuperGridState>();
  final GlobalKey<_DashboardStartSwitchState> _startSwitchKey = GlobalKey();
  final _isEditNotifier = ValueNotifier<bool>(false);
  final _addedWidgetsNotifier = ValueNotifier<List<GridItem>>([]);
  final _menuOpenNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    if (globalState.isAndroidTV) {
      globalState.focusDashboardStartSwitch = _requestStartSwitchFocus;
    }
  }

  void _requestStartSwitchFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startSwitchKey.currentState?.requestFocus();
    });
  }

  @override
  void dispose() {
    if (globalState.focusDashboardStartSwitch == _requestStartSwitchFocus) {
      globalState.focusDashboardStartSwitch = null;
    }
    _isEditNotifier.dispose();
    _addedWidgetsNotifier.dispose();
    _menuOpenNotifier.dispose();
    super.dispose();
  }

  Widget _buildIsEdit(_IsEditWidgetBuilder builder) {
    return ValueListenableBuilder(
      valueListenable: _isEditNotifier,
      builder: (_, isEdit, _) {
        return builder(isEdit);
      },
    );
  }

  List<Widget> _buildActions() {
    final showStartSwitch = ref.watch(
      appSettingProvider.select((state) => state.showStartSwitch),
    );
    final isDark = ref.watch(currentBrightnessProvider) == Brightness.dark;
    return [
      _buildIsEdit((isEdit) {
        return isEdit
            ? ValueListenableBuilder(
                valueListenable: _addedWidgetsNotifier,
                builder: (_, addedChildren, child) {
                  if (addedChildren.isEmpty) {
                    return Container();
                  }
                  return child!;
                },
                child: IconButton(
                  onPressed: () {
                    _showAddWidgetsModal();
                  },
                  icon: Icon(Icons.add_circle),
                ),
              )
            : SizedBox();
      }),
      _buildIsEdit((isEdit) {
        if (isEdit) {
          return IconButton(
            onPressed: _handleUpdateIsEdit,
            tooltip: appLocalizations.save,
            icon: const Icon(Icons.save),
          );
        }
        return CommonPopupBox(
          targetBuilder: (open) {
            final button = IconButton(
              onPressed: () async {
                _menuOpenNotifier.value = true;
                await open(offset: const Offset(0, 20));
                if (!mounted) return;
                _menuOpenNotifier.value = false;
              },
              tooltip: appLocalizations.more,
              icon: showStartSwitch
                  ? ValueListenableBuilder(
                      valueListenable: _menuOpenNotifier,
                      builder: (_, isOpen, _) => _MenuDots(isOpen: isOpen),
                    )
                  : const Icon(Icons.more_vert),
            );
            if (!showStartSwitch) return button;
            return Transform.translate(
              offset: const Offset(4, 0),
              child: button,
            );
          },
          popup: CommonPopupMenu(
            items: [
              PopupMenuItemData(
                icon: Icons.edit,
                label: appLocalizations.edit,
                onPressed: _handleUpdateIsEdit,
              ),
              PopupMenuItemData(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                label: isDark ? appLocalizations.light : appLocalizations.dark,
                onPressed: () {
                  ref
                      .read(themeSettingProvider.notifier)
                      .updateState(
                        (state) => state.copyWith(
                          themeMode: isDark ? ThemeMode.light : ThemeMode.dark,
                        ),
                      );
                },
              ),
              PopupMenuItemData(
                icon: Icons.title,
                label: appLocalizations.customDashboardTitle,
                onPressed: _showEditTitleDialog,
              ),
              PopupMenuItemData(
                icon: Icons.restart_alt,
                label: appLocalizations.restartCoreTitle,
                onPressed: _handleRestartCore,
              ),
            ],
          ),
        );
      }),
      if (showStartSwitch) _DashboardStartSwitch(key: _startSwitchKey),
    ];
  }

  void _showAddWidgetsModal() {
    showSheet(
      builder: (_, type) {
        return ValueListenableBuilder(
          valueListenable: _addedWidgetsNotifier,
          builder: (_, value, _) {
            return AdaptiveSheetScaffold(
              type: type,
              body: _AddDashboardWidgetModal(
                items: value,
                onAdd: (gridItem) {
                  key.currentState?.handleAdd(gridItem);
                },
              ),
              title: appLocalizations.add,
            );
          },
        );
      },
      context: context,
    );
  }

  Future<void> _handleRestartCore() async {
    final result = await globalState.showMessage(
      title: appLocalizations.restartCoreTitle,
      message: TextSpan(text: appLocalizations.restartCoreDesc),
    );
    if (result != true) return;
    await globalState.appController.restartCore();
    globalState.showNotifier(appLocalizations.success);
  }

  void _showEditTitleDialog() async {
    final currentTitle = ref.read(appSettingProvider).dashboardTitle ?? '';
    final title = await globalState.showCommonDialog<String>(
      child: _DashboardTitleDialog(initialValue: currentTitle),
    );
    if (title != null) {
      ref
          .read(appSettingProvider.notifier)
          .updateState(
            (state) =>
                state.copyWith(dashboardTitle: title.isEmpty ? null : title),
          );
    }
  }

  void _handleUpdateIsEdit() {
    if (_isEditNotifier.value == true) {
      _handleSave();
    }
    _isEditNotifier.value = !_isEditNotifier.value;
  }

  void _handleSave() {
    final children = key.currentState?.children;
    if (children == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dashboardWidgets = children
          .map((item) => DashboardWidget.getDashboardWidget(item))
          .toList();
      ref
          .read(appSettingProvider.notifier)
          .updateState(
            (state) => system.isMobile
                ? state.copyWith(
                    mobileDashboardWidgets: dashboardWidgets,
                    dashboardWidgets: dashboardWidgets,
                  )
                : state.copyWith(
                    desktopDashboardWidgets: dashboardWidgets,
                    dashboardWidgets: dashboardWidgets,
                  ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardStateProvider);
    final spacing = 12.mAp;
    final isMobileView = ref.watch(isMobileViewProvider);
    final children = [
      ...dashboardState.dashboardWidgets
          .where(
            (item) => item.platforms.contains(SupportPlatform.currentPlatform),
          )
          .map((item) => item.widget),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _addedWidgetsNotifier.value = DashboardWidget.values
          .where(
            (item) =>
                !children.contains(item.widget) &&
                item.platforms.contains(SupportPlatform.currentPlatform),
          )
          .map((item) => item.widget)
          .toList();
    });
    final title =
        ref.watch(appSettingProvider.select((s) => s.dashboardTitle)) ??
        appLocalizations.dashboard;
    return CommonScaffold(
      title: title,
      titleWidget: globalState.isPre
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: EmojiText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const _PreviewMark(),
              ],
            )
          : null,
      actions: _buildActions(),
      body: ScrollEdgeRise(
        builder: (_, rise) => Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.min(
                constraints.maxWidth,
                dashboardMaxGridWidth,
              );
              final int columns = isMobileView
                  ? 8
                  : DashboardGridBand.of(contentWidth).columns;
              final verticalPadding =
                  32.0 +
                  (isMobileView
                      ? getFloatingBottomBarReserveHeight(context)
                      : 0);
              final unitHeight = dashboardUnitHeight(
                contentWidth,
                availableHeight: constraints.hasBoundedHeight
                    ? constraints.maxHeight - rise
                    : null,
                spacing: spacing,
                verticalPadding: verticalPadding,
              );

              final dashboardContent = ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: dashboardMaxGridWidth,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16).copyWith(
                    top: 16 + rise,
                    bottom:
                        16 +
                        (isMobileView
                            ? getFloatingBottomBarReserveHeight(context)
                            : 0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIsEdit((isEdit) {
                        if (isEdit) {
                          return SystemBackBlock(
                            child: CommonPopScope(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SuperGrid(
                                    key: key,
                                    crossAxisCount: columns,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                    children: [
                                      ...dashboardState.dashboardWidgets
                                          .where(
                                            (item) => item.platforms.contains(
                                              SupportPlatform.currentPlatform,
                                            ),
                                          )
                                          .map((item) => item.widget),
                                    ],
                                    onUpdate: () {
                                      _handleSave();
                                    },
                                  ),
                                ],
                              ),
                              onPop: () {
                                _handleUpdateIsEdit();
                                return false;
                              },
                            ),
                          );
                        } else {
                          return Grid(
                            crossAxisCount: columns,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            children: [...children],
                          );
                        }
                      }),
                    ],
                  ),
                ),
              );

              return DashboardWidgetMetrics(
                unitHeight: unitHeight,
                spacing: spacing,
                columns: columns,
                child: dashboardContent,
              );
            },
          ),
        ),
      ),
    );
  }
}

List<GridItem> packGridItems(List<GridItem> items, int totalColumns) {
  if (items.isEmpty) return const [];
  final pool = List<GridItem>.from(items);
  final packed = <GridItem>[];
  var remainingColumns = totalColumns;

  while (pool.isNotEmpty) {
    final index = pool.indexWhere(
      (item) =>
          math.min(item.crossAxisCellCount, totalColumns) <= remainingColumns,
    );
    if (index != -1) {
      final item = pool.removeAt(index);
      packed.add(item);
      remainingColumns -= math.min(item.crossAxisCellCount, totalColumns);
      if (remainingColumns <= 0) {
        remainingColumns = totalColumns;
      }
    } else {
      remainingColumns = totalColumns;
    }
  }

  return packed;
}

class _AddDashboardWidgetModal extends StatelessWidget {
  final List<GridItem> items;
  final Function(GridItem item) onAdd;

  const _AddDashboardWidgetModal({required this.items, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final spacing = 12.mAp;
    const columns = 8;
    final packedItems = packGridItems(items, columns);
    return DashboardWidgetMetrics(
      unitHeight: 84.0.ap,
      spacing: spacing,
      columns: columns,
      child: DeferredPointerHandler(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Grid(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            children: packedItems
                .map(
                  (item) => item.wrap(
                    builder: (child) {
                      return _AddedContainer(
                        onAdd: () {
                          onAdd(item);
                        },
                        child: child,
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _AddedContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onAdd;

  const _AddedContainer({required this.child, required this.onAdd});

  @override
  State<_AddedContainer> createState() => _AddedContainerState();
}

class _AddedContainerState extends State<_AddedContainer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(_AddedContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {}
  }

  Future<void> _handleAdd() async {
    widget.onAdd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActivateBox(child: widget.child),
        Positioned(
          top: -8,
          right: -8,
          child: DeferPointer(
            child: SizedBox(
              width: 24,
              height: 24,
              child: IconButton.filled(
                iconSize: 20,
                padding: EdgeInsets.all(2),
                onPressed: _handleAdd,
                icon: Icon(Icons.add),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardTitleDialog extends StatefulWidget {
  final String initialValue;

  const _DashboardTitleDialog({required this.initialValue});

  @override
  State<_DashboardTitleDialog> createState() => _DashboardTitleDialogState();
}

class _DashboardTitleDialogState extends State<_DashboardTitleDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate(String value) {
    int len = 0;
    for (int i = 0; i < value.length; i++) {
      len += value.codeUnitAt(i) > 127 ? 2 : 1;
    }
    setState(() {
      if (len > 20) {
        _errorText = appLocalizations.titleTooLong;
      } else {
        _errorText = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.customDashboardTitle,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(appLocalizations.cancel),
        ),
        TextButton(
          onPressed: _errorText == null
              ? () {
                  Navigator.of(context).pop(_controller.text);
                }
              : null,
          child: Text(appLocalizations.confirm),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Have fun with Bettbox',
            errorText: _errorText,
            border: const OutlineInputBorder(),
          ),
          onChanged: _validate,
        ),
      ),
    );
  }
}

class _DashboardStartSwitch extends ConsumerStatefulWidget {
  const _DashboardStartSwitch({super.key});

  @override
  ConsumerState<_DashboardStartSwitch> createState() =>
      _DashboardStartSwitchState();
}

class _DashboardStartSwitchState extends ConsumerState<_DashboardStartSwitch> {
  bool _isDisabled = false;
  bool? _optimisticStart;
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    if (globalState.isAndroidTV) {
      _focusNode = FocusNode()..addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChange);
    _focusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    globalState.isDashboardStartSwitchFocused = _focusNode?.hasFocus ?? false;
  }

  void requestFocus() {
    _focusNode?.requestFocus();
  }

  void _handleStart() async {
    if (_isDisabled) return;
    final isStart = ref.read(runTimeProvider) != null;
    final newState = !isStart;
    setState(() {
      _isDisabled = true;
      _optimisticStart = newState;
    });

    try {
      await globalState.appController.updateStatus(newState);
    } catch (e) {
      commonPrint.error('updateStatus failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDisabled = false;
          _optimisticStart = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(startButtonSelectorStateProvider);
    final isRestarting = ref.watch(isRestartingCoreProvider);
    final isSmartStopped = ref.watch(isSmartStoppedProvider);
    final runTime = ref.watch(runTimeProvider);
    final isStart = runTime != null;
    final displayStart = isSmartStopped ? false : (_optimisticStart ?? isStart);

    final canPress =
        state.isInit &&
        state.hasProfile &&
        !_isDisabled &&
        !isRestarting &&
        !isSmartStopped;

    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final isBusy = _isDisabled || isRestarting;
    final isAvailable = state.isInit && state.hasProfile && !isSmartStopped;
    final (style, onLabel, offLabel) = ref.watch(
      appSettingProvider.select(
        (state) => (
          state.startSwitchStyle,
          state.startSwitchOnLabel,
          state.startSwitchOffLabel,
        ),
      ),
    );
    final isOutlined = style == StartSwitchStyle.outlined;
    final trackColor = isOutlined
        ? isLight
              ? Color.lerp(
                  colorScheme.surface,
                  colorScheme.surfaceContainerLowest,
                  0.5,
                )
              : colorScheme.surfaceContainerHigh
        : displayStart
        ? colorScheme.primary.withValues(alpha: isLight ? 0.12 : 0.2)
        : colorScheme.onSurface.withValues(alpha: 0.06);
    final borderSide = isOutlined
        ? BorderSide(
            color: displayStart
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(
                    alpha: isLight ? 0.45 : 0.25,
                  ),
          )
        : BorderSide.none;
    final iconColor = displayStart
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final labels = [
      (
        offLabel ?? appLocalizations.disabled,
        !displayStart,
        colorScheme.onSurfaceVariant,
      ),
      (onLabel ?? appLocalizations.enabled, displayStart, colorScheme.primary),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimatedOpacity(
        opacity: isAvailable ? 1 : 0.38,
        duration: midDuration,
        child: TextButton(
          focusNode: _focusNode,
          onPressed: canPress ? _handleStart : null,
          style: ButtonStyle(
            visualDensity: VisualDensity.standard,
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            minimumSize: const WidgetStatePropertyAll(Size.zero),
            backgroundColor: WidgetStatePropertyAll(trackColor),
            shape: WidgetStateProperty.resolveWith(
              (states) => StadiumBorder(
                side: states.contains(WidgetState.focused)
                    ? BorderSide(color: colorScheme.primary, width: 2)
                    : borderSide,
              ),
            ),
          ),
          child: Stack(
            children: [
              AnimatedPadding(
                duration: midDuration,
                curve: Curves.easeOutCubic,
                padding: EdgeInsetsDirectional.only(
                  start: displayStart ? 4 : 26,
                  end: displayStart ? 26 : 4,
                ),
                child: SizedBox(
                  height: 24,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final (label, isActive, color) in labels)
                        AnimatedOpacity(
                          opacity: isActive ? 1 : 0,
                          duration: midDuration,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedAlign(
                  duration: midDuration,
                  curve: Curves.easeOutCubic,
                  alignment: displayStart
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: SizedBox.square(
                    dimension: 20,
                    child: Center(
                      child: isBusy
                          ? SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: iconColor,
                              ),
                            )
                          : Icon(
                              Icons.power_settings_new,
                              size: 18,
                              color: iconColor,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewMark extends StatelessWidget {
  const _PreviewMark();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.6)),
      ),
      child: Text(
        kDebugMode ? 'DEBUG' : 'PRE',
        style: context.textTheme.labelSmall?.copyWith(
          fontSize: 9.5,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _MenuDots extends ConsumerWidget {
  final bool isOpen;

  const _MenuDots({required this.isOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStart = ref.watch(runTimeProvider.select((value) => value != null));
    final colorScheme = context.colorScheme;
    final color = IconTheme.of(context).color ?? colorScheme.onSurfaceVariant;
    return AnimatedRotation(
      turns: isOpen ? 0.125 : 0,
      duration: midDuration,
      curve: Curves.easeOutBack,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: isStart ? colorScheme.primary : color),
        duration: midDuration,
        builder: (_, accent, _) => SizedBox.square(
          dimension: 24,
          child: CustomPaint(
            painter: _MenuDotsPainter(color: color, accent: accent ?? color),
          ),
        ),
      ),
    );
  }
}

class _MenuDotsPainter extends CustomPainter {
  final Color color;
  final Color accent;

  const _MenuDotsPainter({required this.color, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 2.6;
    const distance = 5.2;
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color;
    canvas.drawCircle(
      center + const Offset(-distance, -distance),
      radius,
      paint,
    );
    canvas.drawCircle(
      center + const Offset(-distance, distance),
      radius,
      paint,
    );
    canvas.drawCircle(center + const Offset(distance, distance), radius, paint);
    canvas.drawCircle(
      center + const Offset(distance, -distance),
      radius,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_MenuDotsPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.accent != accent;
  }
}
