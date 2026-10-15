import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bett_box/widgets/list.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReferenceItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int count;

  const _ReferenceItem({
    required this.child,
    required this.index,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFirst = index == 0;
    final isLast = index == count - 1;
    final isLight = colorScheme.brightness == Brightness.light;
    final dividerColor = colorScheme.outlineVariant.withValues(
      alpha: isLight ? 0.45 : 0.25,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isLight
            ? Color.lerp(
                colorScheme.surface,
                colorScheme.surfaceContainerLowest,
                0.5,
              )
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (constraints.hasTightHeight)
                  Expanded(
                    child: Align(alignment: Alignment.center, child: child),
                  )
                else
                  child,
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: isLast ? Colors.transparent : dividerColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

typedef _ItemBuilder = Widget Function(int index, int count, Widget child);

Widget _gallery(_ItemBuilder item) {
  Widget content(int index, {double? width}) => Container(
    width: width,
    height: 30.0 + index * 7,
    color: Colors.teal.withValues(alpha: 0.4),
    alignment: Alignment.centerLeft,
    child: Text('row $index'),
  );
  return Column(
    children: [
      for (var i = 0; i < 3; i++)
        SizedBox(height: 60, child: item(i, 3, content(i))),
      const SizedBox(height: 9),
      for (var i = 0; i < 3; i++) item(i, 3, content(i)),
      const SizedBox(height: 9),
      SizedBox(height: 70, child: item(0, 1, content(0, width: 120))),
      const SizedBox(height: 9),
      item(0, 1, content(1, width: 120)),
    ],
  );
}

Future<(ui.Image, ByteData)> _capture(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await boundary.toImage();
  final data = await image.toByteData();
  return (image, data!);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('ContinuousListItem 布局与绘制保持一致 $brightness', (tester) async {
      const referenceKey = ValueKey('reference');
      const candidateKey = ValueKey('candidate');
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: brightness,
            ),
          ),
          home: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RepaintBoundary(
                  key: referenceKey,
                  child: SizedBox(
                    width: 320,
                    height: 560,
                    child: _gallery(
                      (index, count, child) => _ReferenceItem(
                        index: index,
                        count: count,
                        child: child,
                      ),
                    ),
                  ),
                ),
                RepaintBoundary(
                  key: candidateKey,
                  child: SizedBox(
                    width: 320,
                    height: 560,
                    child: _gallery(
                      (index, count, child) => ContinuousListItem(
                        index: index,
                        count: count,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      List<Rect> rects(Finder finder, Key scope) {
        final origin = tester.getTopLeft(find.byKey(scope));
        return [
          for (final element in finder.evaluate())
            tester
                .getRect(find.byElementPredicate((e) => e == element))
                .shift(-origin),
        ];
      }

      Finder within(Key scope, Finder matching) =>
          find.descendant(of: find.byKey(scope), matching: matching);

      expect(
        rects(within(candidateKey, find.byType(Text)), candidateKey),
        rects(within(referenceKey, find.byType(Text)), referenceKey),
      );
      expect(
        rects(
          within(candidateKey, find.byType(ContinuousListItem)),
          candidateKey,
        ),
        rects(within(referenceKey, find.byType(_ReferenceItem)), referenceKey),
      );

      await tester.runAsync(() async {
        final (referenceImage, reference) = await _capture(
          tester,
          referenceKey,
        );
        final (candidateImage, candidate) = await _capture(
          tester,
          candidateKey,
        );
        expect(candidateImage.width, referenceImage.width);
        expect(candidateImage.height, referenceImage.height);
        var different = 0;
        var maxDelta = 0;
        for (var i = 0; i < reference.lengthInBytes; i++) {
          final delta = (reference.getUint8(i) - candidate.getUint8(i)).abs();
          if (delta > 0) different++;
          if (delta > maxDelta) maxDelta = delta;
        }
        expect(different, 0);
        expect(maxDelta, 0);
      });
    });
  }
}
