import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    final selectedRef = currentImagePath ?? (await _imagePicker.pickImage(source: ImageSource.gallery))?.path;
    if (selectedRef == null || selectedRef.isEmpty) {
      return null;
    }

    final sourceBytes = await _loadImageBytesFromRef(selectedRef);
    if (sourceBytes == null || sourceBytes.isEmpty) {
      return null;
    }

    final croppedBytes = await _openCropDialog(
      imageBytes: sourceBytes,
    );
    final extension = _extractImageExtensionFromRef(selectedRef);
    if (croppedBytes == null) {
      if (currentImagePath?.trim().isNotEmpty == true) {
        return currentImagePath;
      }
      return _toDataImageUri(sourceBytes, extension: extension);
    }

    return _toDataImageUri(croppedBytes, extension: extension);
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

  String _extractImageExtensionFromRef(String value) {
    if (value.startsWith('data:image/')) {
      final slash = value.indexOf('/');
      final semicolon = value.indexOf(';', slash + 1);
      if (slash >= 0 && semicolon > slash) {
        final subtype = value.substring(slash + 1, semicolon).toLowerCase();
        if (subtype == 'jpeg' || subtype == 'jpg') {
          return '.jpg';
        }
        if (subtype == 'png' || subtype == 'gif' || subtype == 'bmp') {
          return '.$subtype';
        }
      }
      return '.jpg';
    }
    final normalized = value.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }
    return fileName.substring(dotIndex).toLowerCase();
  }

  Future<Uint8List?> _loadImageBytesFromRef(String imageRef) async {
    if (imageRef.startsWith('data:image/')) {
      final comma = imageRef.indexOf(',');
      if (comma < 0 || comma + 1 >= imageRef.length) {
        return null;
      }
      try {
        return Uint8List.fromList(base64Decode(imageRef.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }

    final source = File(imageRef);
    if (!await source.exists()) {
      return null;
    }
    return source.readAsBytes();
  }

  String _toDataImageUri(Uint8List bytes, {required String extension}) {
    final normalized = extension.startsWith('.') ? extension.toLowerCase() : '.${extension.toLowerCase()}';
    final mime = switch (normalized) {
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.bmp' => 'image/bmp',
      '.jpg' || '.jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
    return 'data:$mime;base64,${base64Encode(bytes)}';
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
