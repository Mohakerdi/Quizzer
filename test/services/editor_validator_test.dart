import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/models/quiz_question.dart';
import 'package:adv_basics/models/question_option.dart';
import 'package:adv_basics/services/editor_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorValidator', () {
    test('returns no errors for valid quiz', () {
      final quiz = QuizModel(
        id: 'id',
        title: 'Valid Quiz',
        version: 1,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        questions: [
          QuizQuestion(
            id: 'q1',
            text: 'Question',
            options: [
              QuestionOption(id: 'o1', text: 'A'),
              QuestionOption(id: 'o2', text: 'B'),
            ],
            correctOptionId: 'o1',
          ),
        ],
      );

      final errors = const EditorValidator().validate(quiz);
      expect(errors, isEmpty);
    });

    test('detects invalid quiz fields', () {
      final quiz = QuizModel(
        id: 'id',
        title: '',
        version: 1,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        questions: [
          QuizQuestion(
            id: 'q1',
            text: '',
            options: [
              QuestionOption(id: 'o1', text: ''),
            ],
            correctOptionId: 'missing',
          ),
        ],
      );

      final errors = const EditorValidator().validate(quiz);
      expect(errors, isNotEmpty);
      expect(errors.join(' '), contains('Quiz title is required'));
      expect(errors.join(' '), contains('at least 2 options'));
      expect(errors.join(' '), contains('select one correct answer'));
    });
  });
}
