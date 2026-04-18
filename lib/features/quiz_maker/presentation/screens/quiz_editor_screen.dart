import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import 'package:adv_basics/core/l10n/app_strings.dart';
import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/editor_validator.dart';
import 'package:adv_basics/features/quiz_maker/presentation/widgets/quiz_editor_panels.dart';
import 'package:adv_basics/features/quiz_maker/presentation/widgets/question_editor_dialog.dart';
import 'package:uuid/uuid.dart';

class QuizEditorScreen extends StatefulWidget {
  const QuizEditorScreen({
    super.key,
    required this.quiz,
    required this.generatedVariants,
    required this.onQuizChanged,
    required this.onQuizAutoSave,
    required this.onGenerateVariants,
    required this.onPreviewVariant,
    required this.onExportVariant,
    required this.onExportAllVariants,
    required this.onExportGoogleForms,
    required this.onAddQuestionToBank,
  });

  final QuizModel quiz;
  final List<GeneratedVariant> generatedVariants;
  final Future<void> Function(QuizModel quiz) onQuizChanged;
  final Future<void> Function(QuizModel quiz) onQuizAutoSave;
  final Future<void> Function(QuizModel quiz) onGenerateVariants;
  final Future<void> Function(GeneratedVariant variant) onPreviewVariant;
  final Future<void> Function(
    GeneratedVariant variant, {
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
  }) onExportVariant;
  final Future<void> Function({
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
  }) onExportAllVariants;
  final Future<void> Function(GeneratedVariant variant) onExportGoogleForms;
  final Future<void> Function(QuizQuestion question) onAddQuestionToBank;

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  static const double _validationDialogMaxWidth = 520;
  static const double _cropDialogWidthFactor = 0.9;
  static const double _cropDialogHeightFactor = 0.65;
  late QuizModel _quiz;
  final _validator = const EditorValidator();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _autosaveDebounce;

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz;
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    unawaited(widget.onQuizAutoSave(_quiz.copyWith(updatedAt: DateTime.now())));
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuizEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz.id != widget.quiz.id || oldWidget.quiz.version != widget.quiz.version) {
      _quiz = widget.quiz;
    }
  }

  Future<void> _save() async {
    _autosaveDebounce?.cancel();
    await widget.onQuizChanged(_quiz.copyWith(updatedAt: DateTime.now()));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(AppStrings.tr(context, 'quizSaved'))));
  }

  void _scheduleAutoSave() {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(widget.onQuizAutoSave(_quiz.copyWith(updatedAt: DateTime.now())));
    });
  }

  Future<void> _validate() async {
    final errors = _validator.validate(_quiz);
    if (!mounted) {
      return;
    }

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(AppStrings.tr(context, 'quizValid'))));
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.tr(context, 'validationErrors')),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _validationDialogMaxWidth),
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
            child: Text(AppStrings.tr(context, 'close')),
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
      final compressedOriginal = await _compressImageBytes(sourceBytes, extension: extension);
      return _toDataImageUri(compressedOriginal, extension: extension);
    }

    final compressedCropped = await _compressImageBytes(croppedBytes, extension: extension);
    return _toDataImageUri(compressedCropped, extension: extension);
  }

  Future<Uint8List> _compressImageBytes(Uint8List bytes, {required String extension}) async {
    final normalized = extension.toLowerCase();
    final format = normalized == '.png' ? CompressFormat.png : CompressFormat.jpeg;
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        format: format,
        quality: 80,
      );
      return compressed.isEmpty ? bytes : compressed;
    } catch (_) {
      return bytes;
    }
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
        final mediaSize = MediaQuery.sizeOf(cropDialogContext);
        var isCropping = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(AppStrings.tr(context, 'editImage')),
            content: SizedBox(
              width: mediaSize.width * _cropDialogWidthFactor,
              height: mediaSize.height * _cropDialogHeightFactor,
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
                  child: Text(AppStrings.tr(context, 'cancel')),
                ),
                FilledButton(
                onPressed: isCropping
                    ? null
                    : () {
                        setDialogState(() => isCropping = true);
                        cropController.crop();
                      },
                  child: Text(isCropping ? AppStrings.tr(context, 'applying') : AppStrings.tr(context, 'apply')),
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
    _scheduleAutoSave();
  }

  Future<void> _openDocxExportDialogAndExport(GeneratedVariant variant) async {
    final exportDetails = await showDialog<_DocxExportDetails>(
      context: context,
      builder: (dialogContext) => const _DocxExportDetailsDialog(),
    );
    if (exportDetails == null) {
      return;
    }
    await widget.onExportVariant(
      variant,
      teacherName: exportDetails.nullableTeacherName,
      schoolName: exportDetails.nullableSchoolName,
      exportLanguageCode: exportDetails.exportLanguageCode,
      optionLabelStyle: exportDetails.optionLabelStyle,
    );
  }

  Future<void> _openDocxExportDialogAndExportAll() async {
    final exportDetails = await showDialog<_DocxExportDetails>(
      context: context,
      builder: (dialogContext) => const _DocxExportDetailsDialog(),
    );
    if (exportDetails == null) {
      return;
    }
    await widget.onExportAllVariants(
      teacherName: exportDetails.nullableTeacherName,
      schoolName: exportDetails.nullableSchoolName,
      exportLanguageCode: exportDetails.exportLanguageCode,
      optionLabelStyle: exportDetails.optionLabelStyle,
    );
  }

  QuizQuestion _cloneQuestionWithNewIds(QuizQuestion source) {
    const uuid = Uuid();
    if (source.options.isEmpty) {
      // Defensive fallback so duplicated questions always remain valid/editable.
      final fallbackOption = QuestionOption(id: uuid.v4(), text: '');
      return source.copyWith(
        id: uuid.v4(),
        options: [fallbackOption],
        correctOptionId: fallbackOption.id,
      );
    }

    final optionIdMap = <String, String>{
      for (final option in source.options) option.id: uuid.v4(),
    };
    final clonedOptions = source.options
        .map(
          (option) => QuestionOption(
            id: optionIdMap[option.id]!,
            text: option.text,
            math: option.math,
          ),
        )
        .toList();
    final duplicatedCorrectOptionId =
        optionIdMap[source.correctOptionId] ?? (clonedOptions.isNotEmpty ? clonedOptions.first.id : '');
    return source.copyWith(
      id: uuid.v4(),
      options: clonedOptions,
      correctOptionId: duplicatedCorrectOptionId,
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
    _scheduleAutoSave();
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
    _scheduleAutoSave();
  }

  void _duplicateQuestion(int index) {
    setState(() {
      final questions = [..._quiz.questions];
      final duplicated = _cloneQuestionWithNewIds(questions[index]);
      questions.insert(index + 1, duplicated);
      _quiz = _quiz.copyWith(questions: questions, updatedAt: DateTime.now());
    });
    _scheduleAutoSave();
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactLayout = constraints.maxWidth < 900;
                if (compactLayout) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          onDuplicateQuestion: _duplicateQuestion,
                          onAddQuestionToBank: (index) => widget.onAddQuestionToBank(_quiz.questions[index]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        flex: 2,
                        child: GeneratedVariantsPanel(
                          generatedVariants: widget.generatedVariants,
                          onPreviewVariant: widget.onPreviewVariant,
                          onExportVariant: _openDocxExportDialogAndExport,
                          onExportAllVariants: _openDocxExportDialogAndExportAll,
                          onExportGoogleForms: widget.onExportGoogleForms,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
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
                        onDuplicateQuestion: _duplicateQuestion,
                        onAddQuestionToBank: (index) => widget.onAddQuestionToBank(_quiz.questions[index]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: GeneratedVariantsPanel(
                        generatedVariants: widget.generatedVariants,
                        onPreviewVariant: widget.onPreviewVariant,
                        onExportVariant: _openDocxExportDialogAndExport,
                        onExportAllVariants: _openDocxExportDialogAndExportAll,
                        onExportGoogleForms: widget.onExportGoogleForms,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DocxExportDetails {
  const _DocxExportDetails({
    required this.teacherName,
    required this.schoolName,
    required this.exportLanguageCode,
    required this.optionLabelStyle,
  });

  final String teacherName;
  final String schoolName;
  final String exportLanguageCode;
  final String optionLabelStyle;

  String? get nullableTeacherName => teacherName.isEmpty ? null : teacherName;
  String? get nullableSchoolName => schoolName.isEmpty ? null : schoolName;
}

class _DocxExportDetailsDialog extends StatefulWidget {
  const _DocxExportDetailsDialog();

  @override
  State<_DocxExportDetailsDialog> createState() => _DocxExportDetailsDialogState();
}

class _DocxExportDetailsDialogState extends State<_DocxExportDetailsDialog> {
  static const double _dialogMaxWidth = 420;
  final _teacherController = TextEditingController();
  final _schoolController = TextEditingController();
  bool _defaultsInitialized = false;
  late String _exportLanguageCode;
  late String _optionLabelStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsInitialized) {
      return;
    }
    _exportLanguageCode = AppStrings.isArabic(context) ? 'ar' : 'en';
    _optionLabelStyle = AppStrings.isArabic(context) ? 'arabic' : 'latin';
    _defaultsInitialized = true;
  }

  @override
  void dispose() {
    _teacherController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.tr(context, 'docxExportDetails')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _teacherController,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(context, 'teacherName'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _schoolController,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(context, 'schoolName'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _exportLanguageCode,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(context, 'exportLanguage'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(AppStrings.tr(context, 'exportLanguageEnglish')),
                  ),
                  DropdownMenuItem(
                    value: 'ar',
                    child: Text(AppStrings.tr(context, 'exportLanguageArabic')),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _exportLanguageCode = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _optionLabelStyle,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(context, 'optionLabelStyle'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'latin',
                    child: Text(AppStrings.tr(context, 'optionLabelStyleLatin')),
                  ),
                  DropdownMenuItem(
                    value: 'arabic',
                    child: Text(AppStrings.tr(context, 'optionLabelStyleArabic')),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _optionLabelStyle = value;
                  });
                },
              ),
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
          onPressed: () => Navigator.of(context).pop(
            _DocxExportDetails(
              teacherName: _teacherController.text.trim(),
              schoolName: _schoolController.text.trim(),
              exportLanguageCode: _exportLanguageCode,
              optionLabelStyle: _optionLabelStyle,
            ),
          ),
          child: Text(AppStrings.tr(context, 'exportDocx')),
        ),
      ],
    );
  }
}
