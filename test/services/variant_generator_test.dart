import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/models/quiz_question.dart';
import 'package:adv_basics/models/question_option.dart';
import 'package:adv_basics/services/variant_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VariantGenerator', () {
    test('keeps correct answer by option id after shuffling', () {
      final q1o1 = QuestionOption(id: 'a1', text: '2');
      final q1o2 = QuestionOption(id: 'a2', text: '3');
      final q2o1 = QuestionOption(id: 'b1', text: '4');
      final q2o2 = QuestionOption(id: 'b2', text: '5');

      final quiz = QuizModel(
        id: 'quiz-1',
        title: 'Math Quiz',
        version: 1,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        questions: [
          QuizQuestion(
            id: 'q1',
            text: '1+1',
            options: [q1o1, q1o2],
            correctOptionId: 'a1',
          ),
          QuizQuestion(
            id: 'q2',
            text: '2+2',
            options: [q2o1, q2o2],
            correctOptionId: 'b1',
          ),
        ],
      );

      final variants = const VariantGenerator().generate(quiz: quiz, count: 5);

      expect(variants, hasLength(5));
      for (final variant in variants) {
        for (final question in variant.questions) {
          expect(
            question.options.any((option) => option.id == question.correctOptionId),
            isTrue,
          );
        }
      }
    });
  });
}
