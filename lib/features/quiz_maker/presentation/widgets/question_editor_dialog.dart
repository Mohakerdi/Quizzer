import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:adv_basics/core/l10n/app_strings.dart';
import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/core/widgets/math_or_text.dart';
import 'package:adv_basics/features/quiz_maker/presentation/widgets/math_input_field.dart';

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
  late final TextEditingController _gradeLevelController;
  late final TextEditingController _unitOfStudyController;
  late final TextEditingController _curriculumController;
  late String _imagePath;
  late List<QuestionOption> _options;
  late String _correctOptionId;

  @override
  void initState() {
    super.initState();
    _questionContentController = TextEditingController(
      text: _mergeLegacyTextAndMath(widget.source.text, widget.source.math),
    );
    _gradeLevelController = TextEditingController(text: widget.source.gradeLevel);
    _unitOfStudyController = TextEditingController(text: widget.source.unitOfStudy);
    _curriculumController = TextEditingController(text: widget.source.curriculum);
    _imagePath = widget.source.imageRef;
    _options = widget.source.options
        .map((o) => QuestionOption(id: o.id, text: o.text, math: o.math))
        .toList();
    _correctOptionId = widget.source.correctOptionId;
  }

  @override
  void dispose() {
    _questionContentController.dispose();
    _gradeLevelController.dispose();
    _unitOfStudyController.dispose();
    _curriculumController.dispose();
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
          title: Text(
            optionIndex == null
                ? AppStrings.tr(context, 'addOption')
                : AppStrings.tr(context, 'editOption'),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _FriendlyMathInput(
                    controller: optionContentController,
                    labelText: AppStrings.tr(context, 'optionContent'),
                    hintText: AppStrings.tr(context, 'optionContentHint'),
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
              child: Text(AppStrings.tr(context, 'cancel')),
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
              child: Text(AppStrings.tr(context, 'save')),
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
      gradeLevel: _gradeLevelController.text.trim(),
      unitOfStudy: _unitOfStudyController.text.trim(),
      curriculum: _curriculumController.text.trim(),
      options: _options,
      correctOptionId: _correctOptionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isNewQuestion
            ? AppStrings.tr(context, 'addQuestionTitle')
            : AppStrings.tr(context, 'editQuestionTitle'),
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FriendlyMathInput(
                controller: _questionContentController,
                labelText: AppStrings.tr(context, 'questionContent'),
                hintText: AppStrings.tr(context, 'questionContentHint'),
                minLines: 3,
                maxLines: 8,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gradeLevelController,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(context, 'gradeLevel'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitOfStudyController,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(context, 'unitOfStudy'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _curriculumController,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(context, 'curriculum'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                    OutlinedButton.icon(
                      onPressed: _selectImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(AppStrings.tr(context, 'selectImageFromGallery')),
                    ),
                  const SizedBox(width: 8),
                  if (_imagePath.trim().isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _cropImage,
                      icon: const Icon(Icons.crop),
                      label: Text(AppStrings.tr(context, 'crop')),
                    ),
                  const SizedBox(width: 8),
                  if (_imagePath.trim().isNotEmpty)
                    TextButton.icon(
                      onPressed: () => setState(() => _imagePath = ''),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(AppStrings.tr(context, 'remove')),
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
                  Text(AppStrings.tr(context, 'options'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _openOptionEditor(),
                    icon: const Icon(Icons.add),
                    label: Text(AppStrings.tr(context, 'addOption')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_options.length, (optionIndex) {
                final option = _options[optionIndex];
                return Card(
                  child: ListTile(
                    title: option.composedText.isEmpty
                        ? Text(AppStrings.tr(context, 'emptyOption'))
                        : MathOrText(
                            option.composedText,
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
          child: Text(AppStrings.tr(context, 'cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_buildUpdatedQuestion()),
          child: Text(AppStrings.tr(context, 'saveQuestion')),
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
        errorBuilder: (ctx, __, ___) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(AppStrings.tr(ctx, 'unableToLoadImage')),
        ),
      );
    }

    return Image.file(
      File(imageRef),
      height: 170,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (ctx, __, ___) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(AppStrings.tr(ctx, 'unableToLoadImage')),
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
  Future<void> _insertEquation() async {
    String currentEquation = '';
    final latex = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.tr(context, 'equationEditorTitle')),
        content: SizedBox(
          width: 620,
          child: MathInputField(
            label: AppStrings.tr(context, 'equationFieldLabel'),
            hint: AppStrings.tr(context, 'equationFieldHint'),
            initialValue: '',
            onChanged: (value) => currentEquation = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppStrings.tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(currentEquation.trim()),
            child: Text(AppStrings.tr(context, 'insertEquation')),
          ),
        ],
      ),
    );
    final normalized = (latex ?? '').trim();
    if (normalized.isEmpty) {
      return;
    }
    final controller = widget.controller;
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final snippet = '\$\$$normalized\$\$';
    final updated = text.replaceRange(start, end, snippet);
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (widget.hintText.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.hintText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: _insertEquation,
            icon: const Icon(Icons.functions),
            label: Text(AppStrings.tr(context, 'insertEquation')),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
