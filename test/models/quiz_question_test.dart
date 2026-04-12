import 'package:flutter_test/flutter_test.dart';

import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_question.dart';

void main() {
  test('serializes and deserializes question bank metadata fields', () {
    final question = QuizQuestion(
      id: 'q1',
      text: 'Sample',
      math: '',
      imageRef: '',
      topic: '',
      difficulty: '',
      gradeLevel: '11th',
      unitOfStudy: 'Unit 2',
      curriculum: 'Algebra',
      sourceBankQuestionId: 'bank-source-1',
      options: const [
        QuestionOption(id: 'o1', text: 'A'),
      ],
      correctOptionId: 'o1',
    );

    final decoded = QuizQuestion.fromJson(question.toJson());

    expect(decoded.gradeLevel, '11th');
    expect(decoded.unitOfStudy, 'Unit 2');
    expect(decoded.curriculum, 'Algebra');
    expect(decoded.sourceBankQuestionId, 'bank-source-1');
  });
}
