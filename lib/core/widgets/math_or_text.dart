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
    final segments = _splitInlineEquations(raw);
    final hasInlineEquations = segments.any((segment) => segment.isEquation);
    if (!hasInlineEquations) {
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
    for (final segment in segments) {
      if (segment.isEquation) {
        final latex = segment.value.trim();
        if (latex.isEmpty) {
          continue;
        }
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
        continue;
      }
      // Convert escaped delimiters back to literal "$$" for plain-text rendering.
      final normalized = FriendlyMathFormatter.format(_unescapeEquationDelimiters(segment.value));
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

  List<_MathSegment> _splitInlineEquations(String source) {
    final segments = <_MathSegment>[];
    var cursor = 0;
    while (cursor < source.length) {
      final start = source.indexOf('$$', cursor);
      if (start < 0) {
        segments.add(_MathSegment(source.substring(cursor), isEquation: false));
        break;
      }
      final escapedStart = start > 0 && source[start - 1] == '\\';
      if (escapedStart) {
        segments.add(_MathSegment(source.substring(cursor, start - 1), isEquation: false));
        segments.add(const _MathSegment(r'$$', isEquation: false));
        cursor = start + 2;
        continue;
      }
      if (start > cursor) {
        segments.add(_MathSegment(source.substring(cursor, start), isEquation: false));
      }
      final end = source.indexOf('$$', start + 2);
      if (end < 0) {
        segments.add(_MathSegment(source.substring(start), isEquation: false));
        break;
      }
      final escapedEnd = end > 0 && source[end - 1] == '\\';
      if (escapedEnd) {
        segments.add(_MathSegment(source.substring(start, end - 1), isEquation: false));
        segments.add(const _MathSegment(r'$$', isEquation: false));
        cursor = end + 2;
        continue;
      }
      segments.add(_MathSegment(source.substring(start + 2, end), isEquation: true));
      cursor = end + 2;
    }
    return segments;
  }

  String _unescapeEquationDelimiters(String value) {
    return value.replaceAll(r'\$\$', r'$$');
  }
}

class _MathSegment {
  const _MathSegment(this.value, {required this.isEquation});

  final String value;
  final bool isEquation;
}
