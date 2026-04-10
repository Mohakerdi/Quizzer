import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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
  static const _symbols = [
    r'\frac{}{}',
    r'\sqrt{}',
    '^{}',
    '_{}',
    r'\pi',
    r'\theta',
    r'\leq',
    r'\geq',
    r'\neq',
    r'\times',
    r'\div',
  ];

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _appendSymbol(String symbol) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.baseOffset < 0 ? text.length : selection.baseOffset;
    final updated = text.replaceRange(cursor, cursor, symbol);
    _controller.text = updated;
    _controller.selection = TextSelection.collapsed(offset: cursor + symbol.length);
    widget.onChanged(_controller.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
          ),
          onChanged: (value) {
            widget.onChanged(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _symbols
              .map(
                (symbol) => ActionChip(
                  label: Text(symbol),
                  onPressed: () => _appendSymbol(symbol),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        if (_controller.text.trim().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Math.tex(
              _controller.text,
              onErrorFallback: (error) => Text(
                'Invalid math expression',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}
