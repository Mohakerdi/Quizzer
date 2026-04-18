import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';

abstract class QuizRepositoryContract {
  Future<List<QuizModel>> loadQuizzes();
  Future<QuizModel> upsertQuiz(QuizModel quiz);
  Future<void> deleteQuiz(String quizId);

  Future<List<QuizQuestion>> loadQuestionBank();
  Future<void> saveQuestionBank(List<QuizQuestion> questions);
  Future<QuizQuestion> upsertQuestionBankQuestion(QuizQuestion question);
  Future<void> deleteQuestionBankQuestion(String bankQuestionId);

  Future<List<GeneratedVariant>> loadVariantsForQuiz(String quizId);
  Future<void> saveVariantsForQuiz(String quizId, List<GeneratedVariant> variants);
  Future<void> deleteVariantsForQuiz(String quizId);
}
