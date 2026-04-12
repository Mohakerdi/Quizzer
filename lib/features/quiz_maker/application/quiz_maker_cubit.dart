import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/data/services/docx_export_service.dart';
import 'package:adv_basics/data/services/google_forms_export_service.dart';
import 'package:adv_basics/data/repositories/quiz_repository.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/variant_generator.dart';
import 'package:adv_basics/features/quiz_maker/application/quiz_maker_state.dart';
import 'package:uuid/uuid.dart';

class QuizMakerCubit extends Cubit<QuizMakerState> {
  QuizMakerCubit({
    required QuizRepository repository,
    required VariantGenerator variantGenerator,
    required DocxExportService docxExportService,
    required GoogleFormsExportService googleFormsExportService,
  })  : _repository = repository,
        _variantGenerator = variantGenerator,
        _docxExportService = docxExportService,
        _googleFormsExportService = googleFormsExportService,
        super(const QuizMakerState.initial());

  final QuizRepository _repository;
  final VariantGenerator _variantGenerator;
  final DocxExportService _docxExportService;
  final GoogleFormsExportService _googleFormsExportService;
  bool get _isArabic => state.locale.languageCode == 'ar';

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, clearMessage: true));

    final quizzes = await _repository.loadQuizzes();
    final questionBank = await _repository.loadQuestionBank();
    final selected = quizzes.isNotEmpty ? quizzes.first : null;
    final variants = selected == null ? <GeneratedVariant>[] : await _repository.loadVariantsForQuiz(selected.id);

    emit(
      state.copyWith(
        quizzes: quizzes,
        questionBank: questionBank,
        selectedQuiz: selected,
        generatedVariants: variants,
        isLoading: false,
      ),
    );
  }

  Future<void> createQuiz(String title) async {
    if (title.trim().isEmpty) {
      return;
    }

    final created = await _repository.upsertQuiz(QuizModel.empty(title.trim()));

    emit(
      state.copyWith(
        quizzes: [...state.quizzes, created],
        selectedQuiz: created,
        generatedVariants: const [],
        message: 'Quiz created.',
      ),
    );
  }

  Future<void> createQuizFromQuestionBank({
    required String title,
    required List<QuizQuestion> questions,
  }) async {
    if (title.trim().isEmpty || questions.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final quiz = QuizModel(
      id: const Uuid().v4(),
      title: title.trim(),
      version: 1,
      questions: questions
          .map((question) => _cloneQuestionForNewQuiz(question, sourceBankQuestionId: question.id))
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
    final created = await _repository.upsertQuiz(quiz);
    emit(
      state.copyWith(
        quizzes: [...state.quizzes, created],
        selectedQuiz: created,
        generatedVariants: const [],
        message: _isArabic ? 'تم إنشاء اختبار من بنك الأسئلة.' : 'Quiz created from question bank.',
      ),
    );
  }

  QuizQuestion _cloneQuestionForNewQuiz(
    QuizQuestion question, {
    required String sourceBankQuestionId,
  }) {
    final optionIdMap = <String, String>{
      for (final option in question.options) option.id: const Uuid().v4(),
    };
    final clonedOptions = question.options
        .map(
          (option) => QuestionOption(
            id: optionIdMap[option.id] ?? const Uuid().v4(),
            text: option.text,
            math: option.math,
          ),
        )
        .toList();
    return QuizQuestion(
      id: const Uuid().v4(),
      text: question.text,
      math: question.math,
      imageRef: question.imageRef,
      topic: question.topic,
      difficulty: question.difficulty,
      gradeLevel: question.gradeLevel,
      unitOfStudy: question.unitOfStudy,
      curriculum: question.curriculum,
      sourceBankQuestionId: sourceBankQuestionId,
      options: clonedOptions,
      correctOptionId: optionIdMap[question.correctOptionId] ?? (clonedOptions.isNotEmpty ? clonedOptions.first.id : ''),
    );
  }

  QuizQuestion _cloneQuestionForBank(QuizQuestion question) {
    final optionIdMap = <String, String>{
      for (final option in question.options) option.id: const Uuid().v4(),
    };
    final clonedOptions = question.options
        .map(
          (option) => QuestionOption(
            id: optionIdMap[option.id] ?? const Uuid().v4(),
            text: option.text,
            math: option.math,
          ),
        )
        .toList();
    return QuizQuestion(
      id: const Uuid().v4(),
      text: question.text,
      math: question.math,
      imageRef: question.imageRef,
      topic: question.topic,
      difficulty: question.difficulty,
      gradeLevel: question.gradeLevel,
      unitOfStudy: question.unitOfStudy,
      curriculum: question.curriculum,
      sourceBankQuestionId: '',
      options: clonedOptions,
      correctOptionId: optionIdMap[question.correctOptionId] ?? (clonedOptions.isNotEmpty ? clonedOptions.first.id : ''),
    );
  }

  Future<void> renameQuiz({required QuizModel quiz, required String title}) async {
    if (title.trim().isEmpty) {
      return;
    }

    final saved = await _repository.upsertQuiz(
      quiz.copyWith(title: title.trim(), updatedAt: DateTime.now()),
    );

    emit(
      state.copyWith(
        quizzes: state.quizzes.map((q) => q.id == saved.id ? saved : q).toList(),
        selectedQuiz: state.selectedQuiz?.id == saved.id ? saved : state.selectedQuiz,
        message: 'Quiz renamed.',
      ),
    );
  }

  Future<void> duplicateQuiz(QuizModel quiz) async {
    final duplicated = await _repository.upsertQuiz(quiz.duplicate());
    emit(
      state.copyWith(
        quizzes: [...state.quizzes, duplicated],
        message: 'Quiz duplicated.',
      ),
    );
  }

  Future<void> deleteQuiz(QuizModel quiz) async {
    await _repository.deleteQuiz(quiz.id);
    await _repository.deleteVariantsForQuiz(quiz.id);

    final remaining = state.quizzes.where((q) => q.id != quiz.id).toList();
    final selected = state.selectedQuiz?.id == quiz.id ? (remaining.isNotEmpty ? remaining.first : null) : state.selectedQuiz;
    final variants = selected == null ? <GeneratedVariant>[] : await _repository.loadVariantsForQuiz(selected.id);

    emit(
      state.copyWith(
        quizzes: remaining,
        selectedQuiz: selected,
        generatedVariants: variants,
        message: 'Quiz deleted.',
      ),
    );
  }

  Future<void> addQuestionToQuestionBank(QuizQuestion question) async {
    final bankQuestion = _cloneQuestionForBank(question);
    final saved = await _repository.upsertQuestionBankQuestion(bankQuestion);
    emit(
      state.copyWith(
        questionBank: [...state.questionBank, saved],
        message: _isArabic ? 'تمت إضافة السؤال إلى بنك الأسئلة.' : 'Question added to question bank.',
      ),
    );
  }

  Future<void> deleteQuestionFromQuestionBank(String bankQuestionId) async {
    await _repository.deleteQuestionBankQuestion(bankQuestionId);
    final questionBank = await _repository.loadQuestionBank();
    emit(
      state.copyWith(
        questionBank: questionBank,
        message: _isArabic ? 'تم حذف السؤال من بنك الأسئلة.' : 'Question deleted from question bank.',
      ),
    );
  }

  Future<void> duplicateQuestionInQuestionBank(QuizQuestion question) async {
    final duplicated = _cloneQuestionForBank(question);
    final saved = await _repository.upsertQuestionBankQuestion(duplicated);
    emit(
      state.copyWith(
        questionBank: [...state.questionBank, saved],
        message: _isArabic ? 'تم نسخ السؤال في بنك الأسئلة.' : 'Question duplicated in question bank.',
      ),
    );
  }

  Future<void> selectQuiz(QuizModel quiz) async {
    final variants = await _repository.loadVariantsForQuiz(quiz.id);
    emit(
      state.copyWith(
        selectedQuiz: quiz,
        generatedVariants: variants,
      ),
    );
  }

  Future<void> saveQuiz(QuizModel quiz) async {
    final saved = await _persistQuiz(quiz);
    emit(
      state.copyWith(
        quizzes: state.quizzes.map((q) => q.id == saved.id ? saved : q).toList(),
        selectedQuiz: saved,
        message: 'Quiz saved.',
      ),
    );
  }

  Future<void> saveQuizSilently(QuizModel quiz) async {
    final saved = await _persistQuiz(quiz);
    emit(
      state.copyWith(
        quizzes: state.quizzes.map((q) => q.id == saved.id ? saved : q).toList(),
        selectedQuiz: saved,
        clearMessage: true,
      ),
    );
  }

  Future<QuizModel> _persistQuiz(QuizModel quiz) async {
    final saved = await _repository.upsertQuiz(quiz);
    return saved;
  }

  Future<void> generateVariants({required QuizModel quiz, required int count}) async {
    if (count < 1) {
      emit(
        state.copyWith(
          message: _isArabic ? 'يرجى إدخال عدد صحيح للنماذج.' : 'Please enter a valid number of variants.',
        ),
      );
      return;
    }

    final variants = _variantGenerator.generate(quiz: quiz, count: count);
    await _repository.saveVariantsForQuiz(quiz.id, variants);

    emit(
      state.copyWith(
        generatedVariants: variants,
        message: _isArabic ? 'تم توليد ${variants.length} نموذج(نماذج).' : 'Generated ${variants.length} variant(s).',
      ),
    );
  }

  Future<void> exportVariant(
    GeneratedVariant variant, {
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
  }) async {
    final quiz = state.selectedQuiz;
    if (quiz == null) {
      return;
    }

    final quizDocPath = await _docxExportService.exportQuizPaper(
      quiz: quiz,
      variant: variant,
      teacherName: teacherName,
      schoolName: schoolName,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
    );
    final solutionDocPath = await _docxExportService.exportSolutions(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
    );

    emit(state.copyWith(message: 'Exported:\n$quizDocPath\n$solutionDocPath'));
  }

  Future<void> exportAllVariants({
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
  }) async {
    final quiz = state.selectedQuiz;
    if (quiz == null) {
      return;
    }
    if (state.generatedVariants.isEmpty) {
      emit(
        state.copyWith(
          message: _isArabic ? 'لا توجد نماذج للتصدير.' : 'No variants to export.',
        ),
      );
      return;
    }

    final exportedPaths = <String>[];
    for (final variant in state.generatedVariants) {
      final quizDocPath = await _docxExportService.exportQuizPaper(
        quiz: quiz,
        variant: variant,
        teacherName: teacherName,
        schoolName: schoolName,
        exportLanguageCode: exportLanguageCode,
        optionLabelStyle: optionLabelStyle,
      );
      final solutionDocPath = await _docxExportService.exportSolutions(
        quiz: quiz,
        variant: variant,
        exportLanguageCode: exportLanguageCode,
        optionLabelStyle: optionLabelStyle,
      );
      exportedPaths
        ..add(quizDocPath)
        ..add(solutionDocPath);
    }

    const previewLimit = 6;
    final shownPaths = exportedPaths.take(previewLimit).join('\n');
    final hiddenCount = exportedPaths.length - previewLimit;
    final arabicHiddenLabel = hiddenCount == 1 ? 'ملف إضافي' : 'ملفات إضافية';
    final hiddenSuffix = hiddenCount > 0
        ? (_isArabic ? '\n... و$hiddenCount $arabicHiddenLabel.' : '\n... and $hiddenCount more file(s).')
        : '';

    emit(
      state.copyWith(
        message: _isArabic
            ? 'تم تصدير جميع النماذج (${state.generatedVariants.length}) بعدد ملفات ${exportedPaths.length}:\n$shownPaths$hiddenSuffix'
            : 'Exported all variants (${state.generatedVariants.length}) with ${exportedPaths.length} files:\n$shownPaths$hiddenSuffix',
      ),
    );
  }

  Future<void> exportVariantToGoogleForms(GeneratedVariant variant) async {
    final quiz = state.selectedQuiz;
    if (quiz == null) {
      return;
    }

    final result = await _googleFormsExportService.exportVariant(
      quiz: quiz,
      variant: variant,
    );
    emit(
      state.copyWith(
        message: 'Google Forms export files created:\n${result.scriptPath}\n${result.jsonPath}',
      ),
    );
  }

  void clearMessage() {
    if (state.message == null) {
      return;
    }
    emit(state.copyWith(clearMessage: true));
  }

  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }

  void toggleThemeMode() {
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: next));
  }
}
