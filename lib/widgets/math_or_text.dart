import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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
    final text = value.trim();
    if (text.isEmpty) {
      return Text('', style: style, maxLines: maxLines, overflow: overflow);
    }

    return Math.tex(
      text,
      textStyle: style ?? DefaultTextStyle.of(context).style,
      onErrorFallback: (_) => Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
