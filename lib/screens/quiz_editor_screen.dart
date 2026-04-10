import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/question_option.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/models/quiz_question.dart';
import 'package:adv_basics/services/editor_validator.dart';

class QuizEditorScreen extends StatefulWidget {
  const QuizEditorScreen({
    super.key,
    required this.quiz,
    required this.generatedVariants,
    required this.onQuizChanged,
    required this.onGenerateVariants,
    required this.onPreviewVariant,
    required this.onExportVariant,
  });

  final QuizModel quiz;
  final List<GeneratedVariant> generatedVariants;
  final Future<void> Function(QuizModel quiz) onQuizChanged;
  final Future<void> Function(QuizModel quiz) onGenerateVariants;
  final Future<void> Function(GeneratedVariant variant) onPreviewVariant;
  final Future<void> Function(GeneratedVariant variant) onExportVariant;

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  late QuizModel _quiz;
  final _validator = const EditorValidator();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz;
  }

  @override
  void didUpdateWidget(covariant QuizEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz.id != widget.quiz.id || oldWidget.quiz.version != widget.quiz.version) {
      _quiz = widget.quiz;
    }
  }

  Future<void> _save() async {
    await widget.onQuizChanged(_quiz.copyWith(updatedAt: DateTime.now()));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Quiz saved.')));
  }

  Future<void> _validate() async {
    final errors = _validator.validate(_quiz);
    if (!mounted) {
      return;
    }

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Quiz is valid.')));
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validation errors'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors.map((error) => Text('• $error')).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickAndCropImage({
    required BuildContext dialogContext,
    String? currentImagePath,
  }) async {
    final selectedPath = currentImagePath ?? (await _imagePicker.pickImage(source: ImageSource.gallery))?.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      return null;
    }

    var resolvedPath = selectedPath;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: selectedPath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop image',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop image'),
          WebUiSettings(
            context: dialogContext,
            presentStyle: WebPresentStyle.dialog,
          ),
        ],
      );
      resolvedPath = cropped?.path ?? selectedPath;
    } catch (_) {
      resolvedPath = selectedPath;
    }

    return _persistImagePath(resolvedPath);
  }

  Future<String> _persistImagePath(String inputPath) async {
    final source = File(inputPath);
    if (!await source.exists()) {
      return inputPath;
    }

    final docs = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docs.path}/question_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final dotIndex = inputPath.lastIndexOf('.');
    final extension = dotIndex >= 0 ? inputPath.substring(dotIndex) : '.jpg';
    final targetPath = '${imagesDir.path}/question_${DateTime.now().microsecondsSinceEpoch}$extension';
    final persisted = await source.copy(targetPath);
    return persisted.path;
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

  Future<void> _editQuestion({QuizQuestion? existing, int? index}) async {
    final source = existing ?? QuizQuestion.create();

    final questionContentController = TextEditingController(
      text: _mergeLegacyTextAndMath(source.text, source.math),
    );
    var imagePath = source.imageRef;
    var options = source.options
        .map(
          (o) => QuestionOption(
            id: o.id,
            text: o.text,
            math: o.math,
          ),
        )
        .toList();
    var correctOptionId = source.correctOptionId;

    Future<void> openOptionEditor({
      int? optionIndex,
      required void Function(void Function()) setQuestionDialogState,
    }) async {
      final existingOption = optionIndex == null ? QuestionOption.create() : options[optionIndex];
      final optionContentController = TextEditingController(
        text: _mergeLegacyTextAndMath(existingOption.text, existingOption.math),
      );

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

                setQuestionDialogState(() {
                  if (optionIndex == null) {
                    options = [...options, option];
                    correctOptionId = options.length == 1 ? option.id : correctOptionId;
                  } else {
                    options[optionIndex] = option;
                  }
                });

                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: Text(existing == null ? 'Add question' : 'Edit question'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: questionContentController,
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
                        onPressed: () async {
                          final selected = await _pickAndCropImage(
                            dialogContext: ctx,
                          );
                          if (selected == null) {
                            return;
                          }
                          setLocalState(() => imagePath = selected);
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Select image from gallery'),
                      ),
                      const SizedBox(width: 8),
                      if (imagePath.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final selected = await _pickAndCropImage(
                              dialogContext: ctx,
                              currentImagePath: imagePath,
                            );
                            if (selected == null) {
                              return;
                            }
                            setLocalState(() => imagePath = selected);
                          },
                          icon: const Icon(Icons.crop),
                          label: const Text('Crop'),
                        ),
                      const SizedBox(width: 8),
                      if (imagePath.trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setLocalState(() => imagePath = ''),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                  if (imagePath.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagePath),
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
                        onPressed: () => openOptionEditor(
                          setQuestionDialogState: setLocalState,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add option'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(options.length, (optionIndex) {
                    final option = options[optionIndex];

                    return Card(
                      child: ListTile(
                        title: Text(option.composedText.isEmpty ? '(empty option)' : option.composedText),
                        leading: Radio<String>(
                          value: option.id,
                          groupValue: correctOptionId,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setLocalState(() => correctOptionId = value);
                          },
                        ),
                        subtitle: Text('ID: ${option.id.substring(0, 8)}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => openOptionEditor(
                                optionIndex: optionIndex,
                                setQuestionDialogState: setLocalState,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: options.length <= 2
                                  ? null
                                  : () {
                                      setLocalState(() {
                                        final removed = options.removeAt(optionIndex);
                                        if (correctOptionId == removed.id && options.isNotEmpty) {
                                          correctOptionId = options.first.id;
                                        }
                                      });
                                    },
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final updated = source.copyWith(
                  text: questionContentController.text,
                  math: '',
                  imageRef: imagePath,
                  options: options,
                  correctOptionId: correctOptionId,
                );

                setState(() {
                  final questions = [..._quiz.questions];
                  if (index == null) {
                    questions.add(updated);
                  } else {
                    questions[index] = updated;
                  }
                  _quiz = _quiz.copyWith(
                    questions: questions,
                    updatedAt: DateTime.now(),
                  );
                });

                Navigator.of(ctx).pop();
              },
              child: const Text('Save question'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeQuestion(int index) {
    if (_quiz.questions.length <= 1) {
      return;
    }

    setState(() {
      final questions = [..._quiz.questions]..removeAt(index);
      _quiz = _quiz.copyWith(questions: questions, updatedAt: DateTime.now());
    });
  }

  void _moveQuestion(int index, int direction) {
    final target = index + direction;
    if (target < 0 || target >= _quiz.questions.length) {
      return;
    }

    setState(() {
      final questions = [..._quiz.questions];
      final current = questions.removeAt(index);
      questions.insert(target, current);
      _quiz = _quiz.copyWith(questions: questions, updatedAt: DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _quiz.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Quiz'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _validate,
                icon: const Icon(Icons.rule),
                label: const Text('Validate'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _editQuestion(),
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => widget.onGenerateVariants(_quiz),
                icon: const Icon(Icons.shuffle),
                label: const Text('Generate Variants'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Card(
                    child: ListView.builder(
                      itemCount: _quiz.questions.length,
                      itemBuilder: (context, index) {
                        final question = _quiz.questions[index];
                        return ListTile(
                          title: Text('Q${index + 1}: ${question.composedPrompt}'),
                          subtitle: Text(
                            'Options: ${question.options.length}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward),
                                onPressed: () => _moveQuestion(index, -1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward),
                                onPressed: () => _moveQuestion(index, 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editQuestion(existing: question, index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: _quiz.questions.length <= 1 ? null : () => _removeQuestion(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Generated Variants', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: widget.generatedVariants.isEmpty
                                ? const Center(child: Text('No variants generated yet.'))
                                : ListView.builder(
                                    itemCount: widget.generatedVariants.length,
                                    itemBuilder: (context, index) {
                                      final variant = widget.generatedVariants[index];
                                      return ListTile(
                                        title: Text(variant.id),
                                        subtitle: Text('${variant.questions.length} question(s)'),
                                        trailing: Wrap(
                                          spacing: 4,
                                          children: [
                                            IconButton(
                                              tooltip: 'Preview',
                                              icon: const Icon(Icons.visibility),
                                              onPressed: () => widget.onPreviewVariant(variant),
                                            ),
                                            IconButton(
                                              tooltip: 'Export DOCX',
                                              icon: const Icon(Icons.download),
                                              onPressed: () => widget.onExportVariant(variant),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
