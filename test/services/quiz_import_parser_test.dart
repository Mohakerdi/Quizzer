import 'package:flutter_test/flutter_test.dart';

import 'package:adv_basics/features/quiz_maker/domain/services/quiz_import_parser.dart';

void main() {
  const parser = QuizImportParser();

  test('parses quiz JSON and preserves math fields', () {
    // JSON string escaping uses \\ so jsonDecode returns single backslashes.
    const rawJson = '''
{
  "schemaVersion": 1,
  "title": "Math Quiz",
  "questions": [
    {
      "text": "Solve",
      "math": "\\\\frac{1}{2}x + 3 = 7",
      "options": [
        {"text": "x = 8", "math": "", "isCorrect": true},
        {"text": "x = 4", "math": ""}
      ]
    }
  ]
}
''';

    final quiz = parser.parseSingleQuiz(rawJson);

    expect(quiz.title, 'Math Quiz');
    expect(quiz.questions, hasLength(1));
    expect(quiz.questions.first.math, '\\frac{1}{2}x + 3 = 7');
    expect(quiz.questions.first.options.first.math, '');
    expect(quiz.questions.first.options.last.math, '');
    expect(quiz.questions.first.correctOptionId, quiz.questions.first.options.first.id);
  });

  test('supports nested quiz object', () {
    const rawJson = '''
{
  "quiz": {
    "title": "Nested",
    "questions": [
      {
        "text": "Q1",
        "options": [
          {"text": "A", "isCorrect": true},
          {"text": "B"}
        ]
      }
    ]
  }
}
''';

    final quiz = parser.parseSingleQuiz(rawJson);

    expect(quiz.title, 'Nested');
    expect(quiz.questions.first.options, hasLength(2));
  });

  test('throws when no questions are provided', () {
    const rawJson = '{"title":"Empty","questions":[]}';
    expect(
      () => parser.parseSingleQuiz(rawJson),
      throwsA(isA<FormatException>()),
    );
  });

  test('wraps latex-like imported text in inline math delimiters', () {
    const rawJson = '''
{
  "title": "Latex Text",
  "questions": [
    {
      "text": "\\\\frac{1}{2}x",
      "options": [
        {"text": "\\\\sqrt{9}", "isCorrect": true},
        {"text": "Regular option"}
      ]
    }
  ]
}
''';

    final quiz = parser.parseSingleQuiz(rawJson);
    final question = quiz.questions.first;

    expect(question.text, r'$$\frac{1}{2}x$$');
    expect(question.options.first.text, r'$$\sqrt{9}$$');
    expect(question.options.last.text, 'Regular option');
  });
}
