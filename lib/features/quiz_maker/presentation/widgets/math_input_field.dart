import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_tex/flutter_tex.dart';

import 'package:adv_basics/core/l10n/app_strings.dart';

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
  late final TextEditingController _controller;
  String _value = '';

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.trim();
    _controller = TextEditingController(text: _value);
  }

  @override
  void didUpdateWidget(covariant MathInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && widget.initialValue.trim() != _controller.text.trim()) {
      _value = widget.initialValue.trim();
      _controller.text = _value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onValueChanged(String value) {
    setState(() => _value = value);
    widget.onChanged(value);
  }

  void _insertSnippet(String snippet) {
    final selection = _controller.selection;
    final text = _controller.text;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final updated = text.replaceRange(start, end, snippet);
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
    _onValueChanged(updated);
  }

  Widget _buildKeyboardButton({
    required String label,
    required String latex,
  }) {
    return OutlinedButton(
      onPressed: () => _insertSnippet(latex),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latex = _value.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            helperText: AppStrings.tr(context, 'mathKeyboardHelper'),
          ),
          onChanged: _onValueChanged,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildKeyboardButton(label: r'\frac{}{}', latex: r'\frac{}{}'),
            _buildKeyboardButton(label: r'\sqrt{}', latex: r'\sqrt{}'),
            _buildKeyboardButton(label: r'x^2', latex: r'^{ }'),
            _buildKeyboardButton(label: r'x_n', latex: r'_{ }'),
            _buildKeyboardButton(label: r'\pi', latex: r'\pi'),
            _buildKeyboardButton(label: r'\theta', latex: r'\theta'),
            _buildKeyboardButton(label: r'\times', latex: r'\times'),
            _buildKeyboardButton(label: r'\div', latex: r'\div'),
            _buildKeyboardButton(label: r'\leq', latex: r'\leq'),
            _buildKeyboardButton(label: r'\geq', latex: r'\geq'),
            _buildKeyboardButton(label: r'\neq', latex: r'\neq'),
            _buildKeyboardButton(label: '(', latex: '('),
            _buildKeyboardButton(label: ')', latex: ')'),
          ],
        ),
        const SizedBox(height: 8),
        if (latex.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Math.tex(
                  latex,
                  onErrorFallback: (error) => Text(
                    AppStrings.tr(context, 'invalidMathExpression'),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: TeXView(
                    child: TeXViewDocument('\$\$$latex\$\$'),
                  ),
                ),
              ],
            ),
          ),
        if (latex.isEmpty)
          Text(
            AppStrings.tr(context, 'equationFieldHint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
