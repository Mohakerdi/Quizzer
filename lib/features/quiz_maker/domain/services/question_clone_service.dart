import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:uuid/uuid.dart';

class QuestionCloneService {
  const QuestionCloneService._();

  static QuizQuestion cloneForNewQuiz(QuizQuestion question) {
    return _cloneQuestion(question, sourceBankQuestionId: question.id);
  }

  static QuizQuestion cloneForQuestionBank(QuizQuestion question) {
    return _cloneQuestion(question, sourceBankQuestionId: '');
  }

  static QuizQuestion _cloneQuestion(
    QuizQuestion question, {
    required String sourceBankQuestionId,
  }) {
    final optionIdMap = <String, String>{
      for (final option in question.options) option.id: const Uuid().v4(),
    };
    final clonedOptions = question.options
        .map(
          (option) => QuestionOption(
            id: optionIdMap[option.id]!,
            text: option.text,
            math: option.math,
          ),
        )
        .toList();
    final mappedCorrectOptionId = optionIdMap[question.correctOptionId];
    if (question.options.isEmpty && question.correctOptionId.trim().isNotEmpty) {
      throw StateError(
        'Cannot clone question "${question.id}": question has no options but has a correct option id.',
      );
    }
    if (mappedCorrectOptionId == null && question.options.isNotEmpty) {
      throw StateError(
        'Cannot clone question "${question.id}": missing correct option mapping for "${question.correctOptionId}".',
      );
    }
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
      correctOptionId: mappedCorrectOptionId ?? '',
    );
  }
}
