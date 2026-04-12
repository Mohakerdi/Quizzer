import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:adv_basics/core/utils/friendly_math_formatter.dart';

class MathOrText extends StatelessWidget {
  const MathOrText(
    this.value, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String value;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return Text('', style: style, maxLines: maxLines, overflow: overflow);
    }
    final equationPattern = RegExp(r'(?<!\\)\$\$(.+?)(?<!\\)\$\$', dotAll: true);
    if (!equationPattern.hasMatch(raw)) {
      final text = FriendlyMathFormatter.format(raw).trim();
      final containsArabic = _containsArabic(text);
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: containsArabic ? TextDirection.rtl : null,
        textAlign: TextAlign.start,
      );
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in equationPattern.allMatches(raw)) {
      if (match.start > cursor) {
        final plainText = raw.substring(cursor, match.start).replaceAll(r'\$\$', r'$$');
        final normalized = FriendlyMathFormatter.format(plainText);
        if (normalized.isNotEmpty) {
          spans.add(TextSpan(text: normalized, style: style));
        }
      }
      final latex = (match.group(1) ?? '').trim();
      if (latex.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(
              latex,
              textStyle: style,
              onErrorFallback: (error) => Text(FriendlyMathFormatter.format(latex), style: style),
            ),
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < raw.length) {
      final tailText = raw.substring(cursor).replaceAll(r'\$\$', r'$$');
      final normalized = FriendlyMathFormatter.format(tailText);
      if (normalized.isNotEmpty) {
        spans.add(TextSpan(text: normalized, style: style));
      }
    }

    final containsArabic = _containsArabic(FriendlyMathFormatter.format(raw));
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.merge(style),
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow,
      textDirection: containsArabic ? TextDirection.rtl : TextDirection.ltr,
    );
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(value);
  }
}
