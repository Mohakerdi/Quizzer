import 'dart:io';

import 'package:flutter/material.dart';

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
                  TextField(
                    controller: optionContentController,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Option content',
                      hintText: 'Write text or formula in one place',
                    ),
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
              TextField(
                controller: _questionContentController,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Question content',
                  hintText: 'Write question text and formulas in one place',
                ),
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
                  child: Image.file(
                    File(_imagePath),
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Unable to load selected image.'),
                    ),
                  ),
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
                    title: Text(option.composedText.isEmpty ? '(empty option)' : option.composedText),
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
                    subtitle: Text('ID: ${option.id.substring(0, 8)}'),
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
