import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_keyboard/math_keyboard.dart';

import 'package:adv_basics/l10n/app_strings.dart';

class MathInputField extends StatefulWidget {
  const MathInputField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint = '',
  });

  final String label;
  final String initialValue;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<MathInputField> createState() => _MathInputFieldState();
}

class _MathInputFieldState extends State<MathInputField> {
  late final MathFieldEditingController _controller;
  String _value = '';

  @override
  void initState() {
    super.initState();
    _controller = MathFieldEditingController();
    _value = widget.initialValue;

    if (_value.trim().isNotEmpty) {
      try {
        final expression = TeXParser(_value).parse();
        _controller.updateValue(expression);
      } catch (_) {
        // Keep empty controller state if initial value cannot be parsed.
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MathField(
          controller: _controller,
          keyboardType: MathKeyboardType.expression,
          variables: const ['x', 'y', 'z', 'a', 'b', 'c'],
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            helperText: AppStrings.tr(context, 'mathKeyboardHelper'),
          ),
          onChanged: (value) {
            setState(() => _value = value);
            widget.onChanged(value);
          },
        ),
        const SizedBox(height: 8),
        if (_value.trim().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Math.tex(
              _value,
              onErrorFallback: (error) => Text(
                AppStrings.tr(context, 'invalidMathExpression'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}
