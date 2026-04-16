import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/data/datasources/quiz_local_data_source.dart';
import 'package:adv_basics/features/quiz_maker/domain/contracts/quiz_repository_contract.dart';

class QuizRepository implements QuizRepositoryContract {
  QuizRepository({
    required QuizLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final QuizLocalDataSource _localDataSource;

  @override
  Future<List<QuizModel>> loadQuizzes() async {
    return _localDataSource.loadQuizzes();
  }

  @override
  Future<QuizModel> upsertQuiz(QuizModel quiz) async {
    final all = await loadQuizzes();
    final existingIndex = all.indexWhere((q) => q.id == quiz.id);
    final updatedQuiz = quiz.copyWith(
      version: quiz.version + 1,
      updatedAt: DateTime.now(),
    );

    if (existingIndex >= 0) {
      all[existingIndex] = updatedQuiz;
    } else {
      all.add(updatedQuiz);
    }

    await _localDataSource.saveQuizzes(all);
    return updatedQuiz;
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    final all = await loadQuizzes();
    final kept = all.where((q) => q.id != quizId).toList();
    await _localDataSource.saveQuizzes(kept);
  }

  @override
  Future<List<QuizQuestion>> loadQuestionBank() async {
    return _localDataSource.loadQuestionBank();
  }

  @override
  Future<void> saveQuestionBank(List<QuizQuestion> questions) async {
    await _localDataSource.saveQuestionBank(questions);
  }

  @override
  Future<QuizQuestion> upsertQuestionBankQuestion(QuizQuestion question) async {
    final all = await loadQuestionBank();
    final existingIndex = all.indexWhere((q) => q.id == question.id);
    if (existingIndex >= 0) {
      all[existingIndex] = question;
    } else {
      all.add(question);
    }
    await saveQuestionBank(all);
    return question;
  }

  @override
  Future<void> deleteQuestionBankQuestion(String bankQuestionId) async {
    final questionBank = await loadQuestionBank();
    final keptBank = questionBank.where((q) => q.id != bankQuestionId).toList();
    await saveQuestionBank(keptBank);
  }

  Future<Map<String, List<GeneratedVariant>>> _loadAllVariants() async {
    return _localDataSource.loadAllVariants();
  }

  @override
  Future<List<GeneratedVariant>> loadVariantsForQuiz(String quizId) async {
    final all = await _loadAllVariants();
    return all[quizId] ?? [];
  }

  @override
  Future<void> saveVariantsForQuiz(String quizId, List<GeneratedVariant> variants) async {
    final all = await _loadAllVariants();
    all[quizId] = variants;
    await _localDataSource.saveAllVariants(all);
  }

  @override
  Future<void> deleteVariantsForQuiz(String quizId) async {
    final all = await _loadAllVariants();
    all.remove(quizId);
    await _localDataSource.saveAllVariants(all);
  }
}
