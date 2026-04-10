import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'package:adv_basics/models/question_option.dart';
import 'package:adv_basics/models/quiz_question.dart';

typedef PickAndCropImage =
    Future<String?> Function({
      String? currentImagePath,
    });

Future<QuizQuestion?> showQuestionEditorDialog({
  required BuildContext context,
  required QuizQuestion source,
  required bool isNewQuestion,
  required PickAndCropImage onPickAndCropImage,
}) {
  return showDialog<QuizQuestion>(
    context: context,
    builder: (ctx) => _QuestionEditorDialog(
      source: source,
      isNewQuestion: isNewQuestion,
      onPickAndCropImage: onPickAndCropImage,
    ),
  );
}

class _QuestionEditorDialog extends StatefulWidget {
  const _QuestionEditorDialog({
    required this.source,
    required this.isNewQuestion,
    required this.onPickAndCropImage,
  });

  final QuizQuestion source;
  final bool isNewQuestion;
  final PickAndCropImage onPickAndCropImage;

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  late final TextEditingController _questionContentController;
  late String _imagePath;
  late List<QuestionOption> _options;
  late String _correctOptionId;

  @override
  void initState() {
    super.initState();
    _questionContentController = TextEditingController(
      text: _mergeLegacyTextAndMath(widget.source.text, widget.source.math),
    );
    _imagePath = widget.source.imageRef;
    _options = widget.source.options
        .map((o) => QuestionOption(id: o.id, text: o.text, math: o.math))
        .toList();
    _correctOptionId = widget.source.correctOptionId;
  }

  @override
  void dispose() {
    _questionContentController.dispose();
    super.dispose();
  }

  Future<void> _openOptionEditor({int? optionIndex}) async {
    final existingOption = optionIndex == null ? QuestionOption.create() : _options[optionIndex];
    final optionContentController = TextEditingController(
      text: _mergeLegacyTextAndMath(existingOption.text, existingOption.math),
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(optionIndex == null ? 'Add option' : 'Edit option'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _FriendlyMathInput(
                    controller: optionContentController,
                    labelText: 'Option content',
                    hintText: 'Write text or formula in one place',
                    minLines: 2,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final option = existingOption.copyWith(
                  text: optionContentController.text,
                  math: '',
                );

                setState(() {
                  if (optionIndex == null) {
                    _options = [..._options, option];
                    _correctOptionId = _options.length == 1 ? option.id : _correctOptionId;
                  } else {
                    _options[optionIndex] = option;
                  }
                });

                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      optionContentController.dispose();
    }
  }

  Future<void> _selectImage() async {
    final selectedImagePath = await widget.onPickAndCropImage();
    if (selectedImagePath == null) {
      return;
    }
    setState(() => _imagePath = selectedImagePath);
  }

  Future<void> _cropImage() async {
    final croppedImagePath = await widget.onPickAndCropImage(currentImagePath: _imagePath);
    if (croppedImagePath == null) {
      return;
    }
    setState(() => _imagePath = croppedImagePath);
  }

  void _removeOptionAt(int optionIndex) {
    if (_options.length <= 2) {
      return;
    }

    setState(() {
      final removed = _options.removeAt(optionIndex);
      if (_correctOptionId == removed.id && _options.isNotEmpty) {
        _correctOptionId = _options.first.id;
      }
    });
  }

  QuizQuestion _buildUpdatedQuestion() {
    return widget.source.copyWith(
      text: _questionContentController.text,
      math: '',
      imageRef: _imagePath,
      options: _options,
      correctOptionId: _correctOptionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNewQuestion ? 'Add question' : 'Edit question'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FriendlyMathInput(
                controller: _questionContentController,
                labelText: 'Question content',
                hintText: 'Write question text and formulas in one place',
                minLines: 3,
                maxLines: 8,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Select image from gallery'),
                  ),
                  const SizedBox(width: 8),
                  if (_imagePath.trim().isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _cropImage,
                      icon: const Icon(Icons.crop),
                      label: const Text('Crop'),
                    ),
                  const SizedBox(width: 8),
                  if (_imagePath.trim().isNotEmpty)
                    TextButton.icon(
                      onPressed: () => setState(() => _imagePath = ''),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                    ),
                ],
              ),
              if (_imagePath.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImagePreview(_imagePath),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _openOptionEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add option'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_options.length, (optionIndex) {
                final option = _options[optionIndex];
                return Card(
                  child: ListTile(
                    title: Text(
                      option.composedText.isEmpty ? '(empty option)' : option.composedText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Radio<String>(
                      value: option.id,
                      groupValue: _correctOptionId,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _correctOptionId = value);
                      },
                    ),
                    subtitle: Text('ID: ${option.id.length > 8 ? option.id.substring(0, 8) : option.id}'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openOptionEditor(optionIndex: optionIndex),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _options.length <= 2 ? null : () => _removeOptionAt(optionIndex),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_buildUpdatedQuestion()),
          child: const Text('Save question'),
        ),
      ],
    );
  }

  Widget _buildImagePreview(String imageRef) {
    final dataBytes = _decodeDataImageBytes(imageRef);
    if (dataBytes != null) {
      return Image.memory(
        dataBytes,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Unable to load selected image.'),
        ),
      );
    }

    return Image.file(
      File(imageRef),
      height: 170,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Unable to load selected image.'),
      ),
    );
  }

  Uint8List? _decodeDataImageBytes(String value) {
    if (!value.startsWith('data:image/')) {
      return null;
    }
    final comma = value.indexOf(',');
    if (comma < 0 || comma + 1 >= value.length) {
      return null;
    }
    try {
      return Uint8List.fromList(base64Decode(value.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }
}

String _mergeLegacyTextAndMath(String text, String math) {
  final normalizedText = text.trim();
  final normalizedMath = math.trim();
  if (normalizedMath.isEmpty) {
    return normalizedText;
  }
  if (normalizedText.isEmpty) {
    return normalizedMath;
  }
  return '$normalizedText\n$normalizedMath';
}

class _FriendlyMathInput extends StatefulWidget {
  const _FriendlyMathInput({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  State<_FriendlyMathInput> createState() => _FriendlyMathInputState();
}

class _FriendlyMathInputState extends State<_FriendlyMathInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _FriendlyMathInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _insert(String value, {int cursorShift = 0}) {
    final current = widget.controller.value;
    final selection = current.selection;
    final start = selection.start >= 0 ? selection.start : current.text.length;
    final end = selection.end >= 0 ? selection.end : current.text.length;
    final updatedText = current.text.replaceRange(start, end, value);
    final cursor = (start + value.length - cursorShift).clamp(0, updatedText.length);
    widget.controller.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  /// Converts friendly inline math tokens to a lightweight LaTeX form for preview.
  ///
  /// Supported patterns are intentionally simple (`√(...)`, `(...)/(...)`, `<=`, `>=`, `!=`).
  /// Nested parentheses inside the sqrt/fraction group are not expanded by this helper.
  String _toLatex(String value) {
    var text = value.trim();
    if (text.isEmpty) {
      return text;
    }
    text = text
        .replaceAll('\\', '')
        .replaceAll('<=', r' \leq ')
        .replaceAll('>=', r' \geq ')
        .replaceAll('!=', r' \neq ')
        .replaceAll('×', r' \times ')
        .replaceAll('÷', r' \div ');
    // Intentionally matches only non-nested `√(...)` groups.
    text = text.replaceAllMapped(RegExp(r'√\(([^()]*)\)'), (m) => r'\sqrt{' '${m.group(1)}' r'}');
    // Intentionally matches only non-nested `(...)/(...)` groups.
    text = text.replaceAllMapped(RegExp(r'\(([^()]*)\)\s*/\s*\(([^()]*)\)'), (m) {
      return r'\frac{' '${m.group(1)}' r'}{' '${m.group(2)}' r'}';
    });
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MathActionChip(label: '√', onTap: () => _insert('√()', cursorShift: 1)),
            _MathActionChip(label: 'Fraction', onTap: () => _insert('()/()', cursorShift: 4)),
            _MathActionChip(label: '≤', onTap: () => _insert(' <= ')),
            _MathActionChip(label: '≥', onTap: () => _insert(' >= ')),
            _MathActionChip(label: '≠', onTap: () => _insert(' != ')),
            _MathActionChip(label: 'π', onTap: () => _insert('π')),
            _MathActionChip(label: 'θ', onTap: () => _insert('θ')),
            _MathActionChip(label: '×', onTap: () => _insert(' × ')),
            _MathActionChip(label: '÷', onTap: () => _insert(' ÷ ')),
            _MathActionChip(label: 'x²', onTap: () => _insert('^2')),
          ],
        ),
        if (text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Math.tex(
              _toLatex(text),
              onErrorFallback: (_) => Text(text),
            ),
          ),
        ],
      ],
    );
  }
}

class _MathActionChip extends StatelessWidget {
  const _MathActionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
