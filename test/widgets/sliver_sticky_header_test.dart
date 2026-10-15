import 'package:bett_box/widgets/sliver_sticky_header.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('吸顶时与顶部保留间距，分组结束时被推出，内容从标题背后经过', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            for (final group in ['a', 'b'])
              SliverStickyHeader(
                spacing: 8,
                pinnedInset: 8,
                headerRadius: 16,
                pinnedShadow: const BoxShadow(blurRadius: 14),
                header: SizedBox(height: 60, child: Text('header $group')),
                sliver: SliverFixedExtentList(
                  itemExtent: 50,
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => Text('$group$index'),
                    childCount: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    double headerTop(String group) =>
        tester.getTopLeft(find.text('header $group')).dy;

    expect(headerTop('a'), 16);

    controller.jumpTo(4);
    await tester.pump();
    expect(headerTop('a'), 12);

    controller.jumpTo(300);
    await tester.pump();
    expect(headerTop('a'), 8);
    expect(tester.getTopLeft(find.text('a5')).dy, 34);

    controller.jumpTo(16 + 68 + 1000 - 30);
    await tester.pump();
    expect(headerTop('a'), -38);

    controller.jumpTo(16 + 68 + 1000 + 100);
    await tester.pump();
    expect(headerTop('b'), 8);
  });
}
