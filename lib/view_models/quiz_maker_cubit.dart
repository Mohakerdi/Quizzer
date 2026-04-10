import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/services/docx_export_service.dart';
import 'package:adv_basics/services/google_forms_export_service.dart';
import 'package:adv_basics/services/quiz_repository.dart';
import 'package:adv_basics/services/variant_generator.dart';
import 'package:adv_basics/view_models/quiz_maker_state.dart';

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
    final selected = quizzes.isNotEmpty ? quizzes.first : null;
    final variants = selected == null ? <GeneratedVariant>[] : await _repository.loadVariantsForQuiz(selected.id);

    emit(
      state.copyWith(
        quizzes: quizzes,
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
    );
    final solutionDocPath = await _docxExportService.exportSolutions(quiz: quiz, variant: variant);

    emit(state.copyWith(message: 'Exported:\n$quizDocPath\n$solutionDocPath'));
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
