import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:adv_basics/utils/friendly_math_formatter.dart';

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
    final text = FriendlyMathFormatter.format(value).trim();
    if (text.isEmpty) {
      return Text('', style: style, maxLines: maxLines, overflow: overflow);
    }

    final containsArabic = _containsArabic(text);
    if (containsArabic) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.start,
      );
    }

    if (!_looksLikeMathExpression(text)) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: null,
        textAlign: TextAlign.start,
      );
    }

    return Math.tex(
      text,
      textStyle: style ?? DefaultTextStyle.of(context).style,
      onErrorFallback: (_) => Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: null,
        textAlign: TextAlign.start,
      ),
    );
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(value);
  }

  bool _looksLikeMathExpression(String value) {
    return RegExp(r'(\\[a-zA-Z]+)|\$\$|\\\$\$|[_^{}]').hasMatch(value);
  }
}
