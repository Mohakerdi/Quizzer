import 'package:flutter/material.dart';
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
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: containsArabic ? TextDirection.rtl : null,
      textAlign: TextAlign.start,
    );
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(value);
  }
}
