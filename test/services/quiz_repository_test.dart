import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/data/datasources/quiz_local_data_source.dart';
import 'package:adv_basics/data/repositories/quiz_repository.dart';

void main() {
  group('QuizRepository question bank behavior', () {
    test('deleting a quiz does not delete question bank entries', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = QuizRepository(
        localDataSource: const SharedPreferencesQuizLocalDataSource(),
      );
      final now = DateTime.now();
      final question = QuizQuestion(
        id: 'bank-q1',
        text: 'Bank question',
        options: const [
          QuestionOption(id: 'o1', text: 'A'),
          QuestionOption(id: 'o2', text: 'B'),
        ],
        correctOptionId: 'o1',
      );
      await repository.saveQuestionBank([question]);
      await repository.upsertQuiz(
        QuizModel(
          id: 'quiz-1',
          title: 'Quiz 1',
          version: 1,
          questions: [QuizQuestion.create()],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.deleteQuiz('quiz-1');

      final remainingBank = await repository.loadQuestionBank();
      expect(remainingBank.map((q) => q.id), contains('bank-q1'));
    });

    test('deleting a bank question does not remove linked questions from quizzes', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = QuizRepository(
        localDataSource: const SharedPreferencesQuizLocalDataSource(),
      );
      final now = DateTime.now();
      final bankQuestion = QuizQuestion(
        id: 'bank-q1',
        text: 'Bank question',
        options: const [
          QuestionOption(id: 'o1', text: 'A'),
          QuestionOption(id: 'o2', text: 'B'),
        ],
        correctOptionId: 'o1',
      );
      final linkedQuizQuestion = QuizQuestion(
        id: 'quiz-q1',
        text: 'Linked question copy',
        sourceBankQuestionId: 'bank-q1',
        options: const [
          QuestionOption(id: 'qo1', text: 'A'),
          QuestionOption(id: 'qo2', text: 'B'),
        ],
        correctOptionId: 'qo1',
      );
      final regularQuizQuestion = QuizQuestion(
        id: 'quiz-q2',
        text: 'Regular question',
        options: const [
          QuestionOption(id: 'ro1', text: 'A'),
          QuestionOption(id: 'ro2', text: 'B'),
        ],
        correctOptionId: 'ro1',
      );

      await repository.saveQuestionBank([bankQuestion]);
      await repository.upsertQuiz(
        QuizModel(
          id: 'quiz-1',
          title: 'Quiz 1',
          version: 1,
          questions: [linkedQuizQuestion, regularQuizQuestion],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.deleteQuestionBankQuestion('bank-q1');

      final quizzes = await repository.loadQuizzes();
      final updatedQuiz = quizzes.singleWhere((quiz) => quiz.id == 'quiz-1');
      final questionIds = updatedQuiz.questions.map((q) => q.id).toList();
      expect(questionIds, contains('quiz-q1'));
      expect(questionIds, contains('quiz-q2'));
    });
  });
}
