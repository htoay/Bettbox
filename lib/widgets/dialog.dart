import 'dart:math';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/providers/app.dart';
import 'package:bett_box/widgets/pop_scope.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bett_box/state.dart';
import 'text.dart';

class CommonDialog extends ConsumerWidget {
  final String title;
  final Widget? titleTrailing;
  final Widget? child;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final bool overrideScroll;
  final Color? backgroundColor;

  const CommonDialog({
    super.key,
    required this.title,
    this.titleTrailing,
    this.actions,
    this.child,
    this.padding,
    this.overrideScroll = false,
    this.backgroundColor,
  });

  List<Widget>? _buildActions(BuildContext context) {
    final actions = this.actions;
    if (actions == null || actions.isEmpty) {
      return actions;
    }
    final colorScheme = context.colorScheme;
    final backgroundColor = colorScheme.primary.opacity12;
    return [
      ...actions.take(actions.length - 1),
      FilledButtonTheme(
        data: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: colorScheme.primary,
            elevation: 0,
          ),
        ),
        child: TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              backgroundColor: backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
          ),
          child: actions.last,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, ref) {
    final size = ref.watch(viewSizeProvider);
    final isTv = globalState.isAndroidTV;
    final theme = Theme.of(context);
    return PopScope(
      canPop: !isTv,
      onPopInvokedWithResult: !isTv
          ? null
          : (didPop, result) {
              if (didPop) return;
              if (dismissTvInputFocus()) return;
              if (ModalRoute.of(context)?.isCurrent != true) return;
              Navigator.of(context).pop();
            },
      child: AlertDialog(
        // flutter_ohos 的框架把鸿蒙上的 AlertDialog 默认改成了 scrollable: true
        // （原版默认 false）。本应用的内容自带 SingleChildScrollView 与固定宽高，
        // 走 fork 的双层滚动 + IntrinsicWidth 结构后在鸿蒙上渲染不出来（只剩遮罩）。
        // 这里显式恢复原版/Android 行为。
        scrollable: false,
        title: titleTrailing == null
            ? EmojiText(title)
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  EmojiText(title),
                  const SizedBox(width: 8),
                  titleTrailing!,
                ],
              ),
        actions: _buildActions(context),
        titleTextStyle: context.textTheme.titleLarge?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: padding ?? const EdgeInsets.fromLTRB(22, 14, 22, 18),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: backgroundColor,
        content: Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              fillColor: theme.brightness == Brightness.light
                  ? theme.colorScheme.surfaceContainer
                  : null,
            ),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: min(size.height - 40, 500),
              maxWidth: 300,
            ),
            width: size.width - 40,
            child: !overrideScroll
                ? SingleChildScrollView(child: child)
                : child,
          ),
        ),
      ),
    );
  }
}

class CommonModal extends ConsumerWidget {
  final Widget? child;

  const CommonModal({super.key, this.child});

  @override
  Widget build(BuildContext context, ref) {
    final size = ref.watch(viewSizeProvider);
    return Center(
      child: Container(
        width: size.width * 0.85,
        height: size.height * 0.85,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

