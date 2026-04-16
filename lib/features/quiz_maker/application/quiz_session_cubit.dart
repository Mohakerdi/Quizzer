import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/features/quiz_maker/application/quiz_session_state.dart';
import 'package:adv_basics/features/quiz_maker/domain/contracts/quiz_repository_contract.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/question_clone_service.dart';
import 'package:adv_basics/features/quiz_maker/domain/usecases/quiz_session_use_cases.dart';

class QuizSessionCubit extends Cubit<QuizSessionState> {
  QuizSessionCubit({
    required QuizRepositoryContract repository,
    required CreateQuizUseCase createQuizUseCase,
    required CreateQuizFromQuestionBankUseCase createQuizFromQuestionBankUseCase,
    required RenameQuizUseCase renameQuizUseCase,
    required DuplicateQuizUseCase duplicateQuizUseCase,
    required GenerateVariantsUseCase generateVariantsUseCase,
    required ExportVariantUseCase exportVariantUseCase,
    required ExportAllVariantsUseCase exportAllVariantsUseCase,
    required ExportVariantToGoogleFormsUseCase exportVariantToGoogleFormsUseCase,
  })  : _repository = repository,
        _createQuizUseCase = createQuizUseCase,
        _createQuizFromQuestionBankUseCase = createQuizFromQuestionBankUseCase,
        _renameQuizUseCase = renameQuizUseCase,
        _duplicateQuizUseCase = duplicateQuizUseCase,
        _generateVariantsUseCase = generateVariantsUseCase,
        _exportVariantUseCase = exportVariantUseCase,
        _exportAllVariantsUseCase = exportAllVariantsUseCase,
        _exportVariantToGoogleFormsUseCase = exportVariantToGoogleFormsUseCase,
        super(const QuizSessionState.initial());

  final QuizRepositoryContract _repository;
  final CreateQuizUseCase _createQuizUseCase;
  final CreateQuizFromQuestionBankUseCase _createQuizFromQuestionBankUseCase;
  final RenameQuizUseCase _renameQuizUseCase;
  final DuplicateQuizUseCase _duplicateQuizUseCase;
  final GenerateVariantsUseCase _generateVariantsUseCase;
  final ExportVariantUseCase _exportVariantUseCase;
  final ExportAllVariantsUseCase _exportAllVariantsUseCase;
  final ExportVariantToGoogleFormsUseCase _exportVariantToGoogleFormsUseCase;

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

    final created = await _createQuizUseCase(title);
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
    required bool isArabic,
  }) async {
    if (title.trim().isEmpty || questions.isEmpty) {
      return;
    }

    final created = await _createQuizFromQuestionBankUseCase(
      title: title,
      questions: questions,
    );
    emit(
      state.copyWith(
        quizzes: [...state.quizzes, created],
        selectedQuiz: created,
        generatedVariants: const [],
        message: isArabic ? 'تم إنشاء اختبار من بنك الأسئلة.' : 'Quiz created from question bank.',
      ),
    );
  }

  Future<void> renameQuiz({
    required QuizModel quiz,
    required String title,
  }) async {
    if (title.trim().isEmpty) {
      return;
    }

    final saved = await _renameQuizUseCase(quiz: quiz, title: title);
    emit(
      state.copyWith(
        quizzes: state.quizzes.map((q) => q.id == saved.id ? saved : q).toList(),
        selectedQuiz: state.selectedQuiz?.id == saved.id ? saved : state.selectedQuiz,
        message: 'Quiz renamed.',
      ),
    );
  }

  Future<void> duplicateQuiz(QuizModel quiz) async {
    final duplicated = await _duplicateQuizUseCase(quiz);
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

  Future<void> addQuestionToQuestionBank({
    required QuizQuestion question,
    required bool isArabic,
  }) async {
    final bankQuestion = QuestionCloneService.cloneForQuestionBank(question);
    final saved = await _repository.upsertQuestionBankQuestion(bankQuestion);
    emit(
      state.copyWith(
        questionBank: [...state.questionBank, saved],
        message: isArabic ? 'تمت إضافة السؤال إلى بنك الأسئلة.' : 'Question added to question bank.',
      ),
    );
  }

  Future<void> deleteQuestionFromQuestionBank({
    required String bankQuestionId,
    required bool isArabic,
  }) async {
    await _repository.deleteQuestionBankQuestion(bankQuestionId);
    final questionBank = await _repository.loadQuestionBank();
    emit(
      state.copyWith(
        questionBank: questionBank,
        message: isArabic ? 'تم حذف السؤال من بنك الأسئلة.' : 'Question deleted from question bank.',
      ),
    );
  }

  Future<void> duplicateQuestionInQuestionBank({
    required QuizQuestion question,
    required bool isArabic,
  }) async {
    final duplicated = QuestionCloneService.cloneForQuestionBank(question);
    final saved = await _repository.upsertQuestionBankQuestion(duplicated);
    emit(
      state.copyWith(
        questionBank: [...state.questionBank, saved],
        message: isArabic ? 'تم نسخ السؤال في بنك الأسئلة.' : 'Question duplicated in question bank.',
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
    final saved = await _repository.upsertQuiz(quiz);
    emit(
      state.copyWith(
        quizzes: state.quizzes.map((q) => q.id == saved.id ? saved : q).toList(),
        selectedQuiz: saved,
        message: 'Quiz saved.',
      ),
    );
  }

  Future<void> saveQuizSilently(QuizModel quiz) async {
    final saved = await _repository.upsertQuiz(quiz);
    emit(
      state.copyWith(
        quizzes: state.quizzes.map((q) => q.id == saved.id ? saved : q).toList(),
        selectedQuiz: saved,
        clearMessage: true,
      ),
    );
  }

  Future<void> generateVariants({
    required QuizModel quiz,
    required int? count,
    required bool isArabic,
  }) async {
    if (count == null || count < 1) {
      emit(
        state.copyWith(
          message: isArabic ? 'يرجى إدخال عدد صحيح للنماذج.' : 'Please enter a valid number of variants.',
        ),
      );
      return;
    }

    final variants = _generateVariantsUseCase(quiz: quiz, count: count);
    await _repository.saveVariantsForQuiz(quiz.id, variants);

    emit(
      state.copyWith(
        generatedVariants: variants,
        message: isArabic ? 'تم توليد ${variants.length} نموذج(نماذج).' : 'Generated ${variants.length} variant(s).',
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
    final paths = await _exportVariantUseCase(
      quiz: quiz,
      variant: variant,
      teacherName: teacherName,
      schoolName: schoolName,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
    );
    emit(state.copyWith(message: 'Exported:\n${paths.join('\n')}'));
  }

  Future<void> exportAllVariants({
    required bool isArabic,
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
          message: isArabic ? 'لا توجد نماذج للتصدير.' : 'No variants to export.',
        ),
      );
      return;
    }

    final exportedPaths = await _exportAllVariantsUseCase(
      quiz: quiz,
      variants: state.generatedVariants,
      teacherName: teacherName,
      schoolName: schoolName,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
    );

    const previewLimit = 6;
    final shownPaths = exportedPaths.take(previewLimit).join('\n');
    final hiddenCount = exportedPaths.length - previewLimit;
    final arabicHiddenLabel = hiddenCount == 1 ? 'ملف إضافي' : 'ملفات إضافية';
    final hiddenSuffix = hiddenCount > 0
        ? (isArabic ? '\n... و$hiddenCount $arabicHiddenLabel.' : '\n... and $hiddenCount more file(s).')
        : '';

    emit(
      state.copyWith(
        message: isArabic
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

    final result = await _exportVariantToGoogleFormsUseCase(quiz: quiz, variant: variant);
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
}
