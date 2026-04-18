import 'package:flutter_test/flutter_test.dart';

import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/features/quiz_maker/domain/contracts/quiz_repository_contract.dart';
import 'package:adv_basics/features/quiz_maker/domain/usecases/quiz_session_use_cases.dart';

class _InMemoryQuizRepository implements QuizRepositoryContract {
  final List<QuizModel> _quizzes = [];
  final List<QuizQuestion> _questionBank = [];
  final Map<String, List<GeneratedVariant>> _variants = {};

  @override
  Future<void> deleteQuestionBankQuestion(String bankQuestionId) async {
    _questionBank.removeWhere((q) => q.id == bankQuestionId);
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    _quizzes.removeWhere((q) => q.id == quizId);
  }

  @override
  Future<void> deleteVariantsForQuiz(String quizId) async {
    _variants.remove(quizId);
  }

  @override
  Future<List<QuizQuestion>> loadQuestionBank() async => List<QuizQuestion>.from(_questionBank);

  @override
  Future<List<QuizModel>> loadQuizzes() async => List<QuizModel>.from(_quizzes);

  @override
  Future<List<GeneratedVariant>> loadVariantsForQuiz(String quizId) async => List<GeneratedVariant>.from(_variants[quizId] ?? const []);

  @override
  Future<void> saveQuestionBank(List<QuizQuestion> questions) async {
    _questionBank
      ..clear()
      ..addAll(questions);
  }

  @override
  Future<void> saveVariantsForQuiz(String quizId, List<GeneratedVariant> variants) async {
    _variants[quizId] = variants;
  }

  @override
  Future<QuizQuestion> upsertQuestionBankQuestion(QuizQuestion question) async {
    final index = _questionBank.indexWhere((q) => q.id == question.id);
    if (index >= 0) {
      _questionBank[index] = question;
    } else {
      _questionBank.add(question);
    }
    return question;
  }

  @override
  Future<QuizModel> upsertQuiz(QuizModel quiz) async {
    final index = _quizzes.indexWhere((q) => q.id == quiz.id);
    final updated = quiz.copyWith(
      version: quiz.version + 1,
      updatedAt: DateTime.now(),
    );
    if (index >= 0) {
      _quizzes[index] = updated;
    } else {
      _quizzes.add(updated);
    }
    return updated;
  }
}

void main() {
  test('CreateQuizFromQuestionBankUseCase clones questions and preserves source linkage', () async {
    final repository = _InMemoryQuizRepository();
    final useCase = CreateQuizFromQuestionBankUseCase(repository);
    final bankQuestion = QuizQuestion(
      id: 'bank-q1',
      text: 'Prompt',
      options: const [
        QuestionOption(id: 'o1', text: 'A'),
        QuestionOption(id: 'o2', text: 'B'),
      ],
      correctOptionId: 'o1',
    );

    final created = await useCase(
      title: 'My Quiz',
      questions: [bankQuestion],
    );

    expect(created.title, 'My Quiz');
    expect(created.questions, hasLength(1));
    expect(created.questions.first.id, isNot(bankQuestion.id));
    expect(created.questions.first.sourceBankQuestionId, 'bank-q1');
    expect(created.questions.first.correctOptionId, isNotEmpty);
    expect(
      created.questions.first.options.map((o) => o.id).toSet(),
      isNot(containsAll(['o1', 'o2'])),
    );
  });
}
