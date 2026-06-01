import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/features/quiz_maker/application/quiz_session_state.dart';
import 'package:adv_basics/features/quiz_maker/domain/contracts/quiz_repository_contract.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/editor_validator.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/question_clone_service.dart';
import 'package:adv_basics/features/quiz_maker/domain/usecases/quiz_session_use_cases.dart';

class QuizSessionCubit extends Cubit<QuizSessionState> {
  QuizSessionCubit({
    required QuizRepositoryContract repository,
    required CreateQuizUseCase createQuizUseCase,
    required ImportQuizFromJsonUseCase importQuizFromJsonUseCase,
    required CreateQuizFromQuestionBankUseCase createQuizFromQuestionBankUseCase,
    required RenameQuizUseCase renameQuizUseCase,
    required DuplicateQuizUseCase duplicateQuizUseCase,
    required GenerateVariantsUseCase generateVariantsUseCase,
    required ExportVariantUseCase exportVariantUseCase,
    required ExportAllVariantsUseCase exportAllVariantsUseCase,
    required ExportVariantToGoogleFormsUseCase exportVariantToGoogleFormsUseCase,
  })  : _repository = repository,
        _createQuizUseCase = createQuizUseCase,
        _importQuizFromJsonUseCase = importQuizFromJsonUseCase,
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
  final ImportQuizFromJsonUseCase _importQuizFromJsonUseCase;
  final CreateQuizFromQuestionBankUseCase _createQuizFromQuestionBankUseCase;
  final RenameQuizUseCase _renameQuizUseCase;
  final DuplicateQuizUseCase _duplicateQuizUseCase;
  final GenerateVariantsUseCase _generateVariantsUseCase;
  final ExportVariantUseCase _exportVariantUseCase;
  final ExportAllVariantsUseCase _exportAllVariantsUseCase;
  final ExportVariantToGoogleFormsUseCase _exportVariantToGoogleFormsUseCase;
  final EditorValidator _editorValidator = const EditorValidator();

  Future<Map<String, int>> _loadVariantCountsForQuizzes(List<QuizModel> quizzes) async {
    final entries = <String, int>{};
    for (final quiz in quizzes) {
      final variants = await _repository.loadVariantsForQuiz(quiz.id);
      entries[quiz.id] = variants.length;
    }
    return entries;
  }

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, clearMessage: true));

    final quizzes = await _repository.loadQuizzes();
    final questionBank = await _repository.loadQuestionBank();
    final selected = quizzes.isNotEmpty ? quizzes.first : null;
    final variants = selected == null ? <GeneratedVariant>[] : await _repository.loadVariantsForQuiz(selected.id);
    final variantCountsByQuizId = await _loadVariantCountsForQuizzes(quizzes);

    emit(
      state.copyWith(
        quizzes: quizzes,
        questionBank: questionBank,
        selectedQuiz: selected,
        generatedVariants: variants,
        variantCountsByQuizId: variantCountsByQuizId,
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
        variantCountsByQuizId: {
          ...state.variantCountsByQuizId,
          created.id: 0,
        },
        message: 'Quiz created.',
      ),
    );
  }

  Future<void> importQuizFromJson({
    required String rawJson,
    required bool isArabic,
  }) async {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          message: isArabic ? 'يرجى إدخال JSON للاستيراد.' : 'Please provide JSON to import.',
        ),
      );
      return;
    }

    try {
      final imported = await _importQuizFromJsonUseCase(trimmed);
      emit(
        state.copyWith(
          quizzes: [...state.quizzes, imported],
          selectedQuiz: imported,
          generatedVariants: const [],
          variantCountsByQuizId: {
            ...state.variantCountsByQuizId,
            imported.id: 0,
          },
          message: isArabic ? 'تم استيراد الاختبار بنجاح.' : 'Quiz imported successfully.',
        ),
      );
    } on FormatException catch (error) {
      emit(
        state.copyWith(
          message: isArabic
              ? 'تعذر استيراد JSON: ${error.message}'
              : 'Unable to import JSON: ${error.message}',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          message: isArabic ? 'حدث خطأ أثناء الاستيراد.' : 'An error occurred during import.',
        ),
      );
    }
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
        variantCountsByQuizId: {
          ...state.variantCountsByQuizId,
          created.id: 0,
        },
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
        variantCountsByQuizId: {
          ...state.variantCountsByQuizId,
          duplicated.id: 0,
        },
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
    final variantCountsByQuizId = Map<String, int>.from(state.variantCountsByQuizId)..remove(quiz.id);
    if (selected != null) {
      variantCountsByQuizId[selected.id] = variants.length;
    }

    emit(
      state.copyWith(
        quizzes: remaining,
        selectedQuiz: selected,
        generatedVariants: variants,
        variantCountsByQuizId: variantCountsByQuizId,
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
        variantCountsByQuizId: {
          ...state.variantCountsByQuizId,
          quiz.id: variants.length,
        },
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
    final errors = _editorValidator.validate(quiz);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          message: isArabic
              ? 'لا يمكن توليد النماذج قبل تصحيح الأخطاء: ${errors.first}'
              : 'Cannot generate variants until validation errors are fixed: ${errors.first}',
        ),
      );
      return;
    }

    if (count == null || count < 1 || count > 20) {
      emit(
        state.copyWith(
          message: isArabic ? 'أدخل عدد نماذج من 1 إلى 20.' : 'Enter a variant count between 1 and 20.',
        ),
      );
      return;
    }

    final variants = _generateVariantsUseCase(quiz: quiz, count: count);
    await _repository.saveVariantsForQuiz(quiz.id, variants);

    emit(
      state.copyWith(
        generatedVariants: variants,
        variantCountsByQuizId: {
          ...state.variantCountsByQuizId,
          quiz.id: variants.length,
        },
        message: isArabic ? 'تم توليد ${variants.length} نموذج(نماذج).' : 'Generated ${variants.length} variant(s).',
      ),
    );
  }

  Future<void> exportVariant(
    GeneratedVariant variant, {
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
    final hiddenFilesTextArabic = hiddenCount == 1 ? 'ملف إضافي' : 'ملفات إضافية';
    final hiddenSuffix = hiddenCount > 0
        ? (isArabic ? '\n... و$hiddenCount $hiddenFilesTextArabic.' : '\n... and $hiddenCount more file(s).')
        : '';

    emit(
      state.copyWith(
        message: isArabic
            ? 'تم تصدير جميع النماذج (${state.generatedVariants.length}) بعدد ملفات ${exportedPaths.length}:\n$shownPaths$hiddenSuffix'
            : 'Exported all variants (${state.generatedVariants.length}) with ${exportedPaths.length} files:\n$shownPaths$hiddenSuffix',
      ),
    );
  }

  Future<void> exportVariantToGoogleForms(
    GeneratedVariant variant, {
    required bool isArabic,
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

    final result = await _exportVariantToGoogleFormsUseCase(quiz: quiz, variant: variant);
    emit(
      state.copyWith(
        message: 'Google Forms export files created:\n${result.scriptPath}\n${result.jsonPath}',
      ),
    );
  }

  Future<void> addQuestionFromQuestionBankToSelectedQuiz({
    required QuizQuestion bankQuestion,
    required bool isArabic,
  }) async {
    final selectedQuiz = state.selectedQuiz;
    if (selectedQuiz == null) {
      emit(
        state.copyWith(
          message: isArabic
              ? 'اختر اختبارًا أولًا لإضافة السؤال إليه.'
              : 'Select a quiz first to add this question.',
        ),
      );
      return;
    }

    final cloned = QuestionCloneService.cloneForNewQuiz(bankQuestion);
    final updatedQuiz = selectedQuiz.copyWith(
      questions: [...selectedQuiz.questions, cloned],
      updatedAt: DateTime.now(),
    );
    final saved = await _repository.upsertQuiz(updatedQuiz);
    emit(
      state.copyWith(
        quizzes: state.quizzes.map((q) => q.id == saved.id ? saved : q).toList(),
        selectedQuiz: saved,
        message: isArabic ? 'تمت إضافة السؤال إلى الاختبار الحالي.' : 'Question added to current quiz.',
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
