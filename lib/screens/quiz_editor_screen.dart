import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/models/quiz_question.dart';
import 'package:adv_basics/services/editor_validator.dart';
import 'package:adv_basics/widgets/quiz_editor_panels.dart';
import 'package:adv_basics/widgets/question_editor_dialog.dart';

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

  Future<String?> _pickAndCropImage({String? currentImagePath}) async {
    final selectedPath = currentImagePath ?? (await _imagePicker.pickImage(source: ImageSource.gallery))?.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      return null;
    }

    final source = File(selectedPath);
    if (!await source.exists()) {
      return null;
    }

    final sourceBytes = await source.readAsBytes();
    final croppedBytes = await _openCropDialog(
      imageBytes: sourceBytes,
    );
    if (croppedBytes == null) {
      if (currentImagePath?.trim().isNotEmpty == true) {
        return currentImagePath;
      }
      return _persistImagePath(selectedPath);
    }

    final extension = _extractImageExtension(selectedPath);
    return _persistImageBytes(croppedBytes, extension: extension);
  }

  Future<Uint8List?> _openCropDialog({
    required Uint8List imageBytes,
  }) async {
    final cropController = CropController();
    final completer = Completer<Uint8List?>();

    if (!mounted) {
      return null;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (cropDialogContext) {
        var isCropping = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Edit image'),
            content: SizedBox(
              width: 720,
              height: 520,
              child: Crop(
                image: imageBytes,
                controller: cropController,
                interactive: true,
                onCropped: (result) {
                  if (!completer.isCompleted) {
                    if (result is CropSuccess) {
                      completer.complete(result.croppedImage);
                    } else {
                      completer.complete(null);
                    }
                  }

                  if (Navigator.of(cropDialogContext).canPop()) {
                    Navigator.of(cropDialogContext).pop();
                  }
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!completer.isCompleted) {
                    completer.complete(null);
                  }
                  Navigator.of(cropDialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isCropping
                    ? null
                    : () {
                        setDialogState(() => isCropping = true);
                        cropController.crop();
                      },
                child: Text(isCropping ? 'Applying...' : 'Apply'),
              ),
            ],
          ),
        );
      },
    );

    try {
      return await completer.future;
    } catch (_) {
      return null;
    }
  }

  String _extractImageExtension(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }
    return fileName.substring(dotIndex);
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

  Future<String> _persistImageBytes(Uint8List bytes, {required String extension}) async {
    final docs = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docs.path}/question_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final normalizedExtension = extension.startsWith('.') ? extension : '.$extension';
    final targetPath =
        '${imagesDir.path}/question_${DateTime.now().microsecondsSinceEpoch}$normalizedExtension';
    final file = File(targetPath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _editQuestion({QuizQuestion? existing, int? index}) async {
    final source = existing ?? QuizQuestion.create();
    final updated = await showQuestionEditorDialog(
      context: context,
      source: source,
      isNewQuestion: existing == null,
      onPickAndCropImage: ({currentImagePath}) => _pickAndCropImage(currentImagePath: currentImagePath),
    );
    if (updated == null) {
      return;
    }

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
          QuizEditorActionsBar(
            onSave: _save,
            onValidate: _validate,
            onAddQuestion: () => _editQuestion(),
            onGenerateVariants: () => widget.onGenerateVariants(_quiz),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: QuizQuestionsPanel(
                    questions: _quiz.questions,
                    onMoveQuestion: _moveQuestion,
                    onEditQuestion: (index) {
                      _editQuestion(existing: _quiz.questions[index], index: index);
                    },
                    onRemoveQuestion: _removeQuestion,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GeneratedVariantsPanel(
                    generatedVariants: widget.generatedVariants,
                    onPreviewVariant: widget.onPreviewVariant,
                    onExportVariant: widget.onExportVariant,
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
