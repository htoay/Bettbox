import 'package:bett_box/widgets/builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('转场期间只构建可见行，结束后补齐缓存区且不重建已有行', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final builds = <int, int>{};
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        home: const Scaffold(body: Text('home')),
      ),
    );

    key.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) {
          final slivers = [
            SliverFixedExtentList(
              itemExtent: 100,
              delegate: SliverChildBuilderDelegate((_, index) {
                builds[index] = (builds[index] ?? 0) + 1;
                return Text('row $index');
              }, childCount: 100),
            ),
          ];
          return Scaffold(
            body: RouteScrollCacheBuilder(
              builder: (_, cacheExtent) => CustomScrollView(
                scrollCacheExtent: cacheExtent,
                slivers: slivers,
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(builds.length, 6);

    await tester.pumpAndSettle();
    expect(builds.length, greaterThan(6));
    expect(builds.values.every((count) => count == 1), isTrue);
  });

  testWidgets('不在转场中的页面首帧后即恢复默认缓存区', (tester) async {
    final builds = <int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteScrollCacheBuilder(
            builder: (_, cacheExtent) => CustomScrollView(
              scrollCacheExtent: cacheExtent,
              slivers: [
                SliverFixedExtentList(
                  itemExtent: 100,
                  delegate: SliverChildBuilderDelegate((_, index) {
                    builds.add(index);
                    return Text('row $index');
                  }, childCount: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(builds.length, 6);
    await tester.pump();
    expect(builds.length, greaterThan(6));
  });
}
