import 'package:emoji_regex/emoji_regex.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:material_ui/material_ui.dart';

import '../state.dart';

class TooltipText extends StatelessWidget {
  final Widget text;

  const TooltipText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, container) {
        final maxWidth = container.maxWidth;
        Text? textWidget;
        String? message;
        if (text is Text) {
          textWidget = text as Text;
          message = textWidget.data;
        } else if (text is EmojiText) {
          final emojiText = text as EmojiText;
          textWidget = Text(
            emojiText.text,
            style: emojiText.style,
            maxLines: emojiText.maxLines,
            overflow: emojiText.overflow,
          );
          message = emojiText.text;
        }
        if (textWidget != null) {
          final size = globalState.measure.computeTextSize(textWidget);
          if (maxWidth < size.width) {
            return Tooltip(
              triggerMode: TooltipTriggerMode.longPress,
              preferBelow: false,
              message: message,
              child: text,
            );
          }
        }
        return text;
      },
    );
  }
}

class EmojiText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  static final _emojiRegex = emojiRegex();

  const EmojiText(
    this.text, {
    super.key,
    this.maxLines,
    this.overflow,
    this.style,
    this.textAlign,
  });

  static List<TextSpan> buildSpans(String text, TextStyle style) {
    if (text.isEmpty) {
      return const [];
    }

    if (!_emojiRegex.hasMatch(text)) {
      return [TextSpan(text: text, style: style)];
    }

    final emojiStyle = style.merge(
      TextStyle(
        fontFamily: FontFamily.twEmoji.value,
        fontFamilyFallback: [FontFamily.twEmoji.value],
      ),
    );

    final List<TextSpan> spans = [];
    int segmentStart = 0;
    int currentIndex = 0;
    bool? isEmojiSegment;

    for (final char in text.characters) {
      final isEmoji = _emojiRegex.hasMatch(char);
      if (isEmojiSegment == null) {
        isEmojiSegment = isEmoji;
      } else if (isEmojiSegment != isEmoji) {
        spans.add(
          TextSpan(
            text: text.substring(segmentStart, currentIndex),
            style: isEmojiSegment ? emojiStyle : style,
          ),
        );
        segmentStart = currentIndex;
        isEmojiSegment = isEmoji;
      }
      currentIndex += char.length;
    }

    if (segmentStart < text.length && isEmojiSegment != null) {
      spans.add(
        TextSpan(
          text: text.substring(segmentStart, text.length),
          style: isEmojiSegment ? emojiStyle : style,
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;

    return Text.rich(
      TextSpan(children: buildSpans(text, defaultStyle.merge(style))),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
