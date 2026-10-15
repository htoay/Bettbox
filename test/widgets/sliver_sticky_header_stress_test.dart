import 'dart:math' as math;

import 'package:bett_box/widgets/sliver_sticky_header.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

class _Harness extends StatefulWidget {
  const _Harness({super.key, required this.controller, required this.pinned});

  final ScrollController controller;
  final bool pinned;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness>
    with SingleTickerProviderStateMixin {
  static final _slide = Tween<Offset>(
    begin: const Offset(0, -0.16),
    end: Offset.zero,
  );
  final unfold = <String>{};
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  String? _expanding;

  void toggle(String name) {
    setState(() {
      if (!unfold.remove(name)) {
        unfold.add(name);
        _expanding = name;
        _expand.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.controller,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        for (final name in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'])
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverStickyHeader(
              key: ValueKey('group_$name'),
              pinned: widget.pinned,
              spacing: 8,
              pinnedInset: 8,
              headerRadius: 16,
              pinnedShadow: const BoxShadow(blurRadius: 14),
              header: SizedBox(
                height: 68,
                child: Material(
                  child: InkWell(
                    key: ValueKey('toggle_$name'),
                    onTap: () => toggle(name),
                    child: Text('header $name'),
                  ),
                ),
              ),
              sliver: SliverFixedExtentList(
                itemExtent: 70,
                delegate: SliverChildBuilderDelegate((_, index) {
                  final begin = math.min(index, 6) * 0.07;
                  final Animation<double> animation = name == _expanding
                      ? _expand.drive(
                          CurveTween(
                            curve: Interval(
                              begin,
                              begin + 0.58,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        )
                      : kAlwaysCompleteAnimation;
                  return Padding(
                    key: ValueKey('row_${name}_$index'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(_slide),
                        child: Text('$name$index'),
                      ),
                    ),
                  );
                }, childCount: unfold.contains(name) ? 300 : 0),
              ),
            ),
          ),
      ],
    );
  }
}

void main() {
  for (final pinned in [true, false]) {
    testWidgets('快速连续展开收起不抛异常 pinned=$pinned', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final key = GlobalKey<_HarnessState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _Harness(key: key, controller: controller, pinned: pinned),
          ),
        ),
      );
      final random = math.Random(7);
      const names = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
      for (var i = 0; i < 200; i++) {
        final name = names[random.nextInt(names.length)];
        key.currentState!.toggle(name);
        if (random.nextBool()) {
          await tester.pump(Duration(milliseconds: random.nextInt(40)));
        }
        if (random.nextInt(4) == 0 && controller.hasClients) {
          final max = controller.position.maxScrollExtent;
          controller.jumpTo(random.nextDouble() * max);
          await tester.pump(Duration(milliseconds: random.nextInt(20)));
        }
        if (random.nextInt(5) == 0) {
          final finder = find.byKey(ValueKey('toggle_$name'));
          if (finder.evaluate().isNotEmpty) {
            await tester.tap(finder, warnIfMissed: false);
          }
        }
        expect(tester.takeException(), isNull, reason: 'step $i');
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
