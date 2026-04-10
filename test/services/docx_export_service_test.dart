import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/question_option.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/services/docx_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds quiz and solution document XML with table rows', () {
    final quiz = QuizModel.empty('Geometry');
    final variant = GeneratedVariant(
      id: 'V1',
      quizId: quiz.id,
      seed: 1,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'Triangle angle',
          math: '',
          imageRef: 'image.png',
          correctOptionId: 'o1',
          options: [
            QuestionOption(id: 'o1', text: '80'),
            QuestionOption(id: 'o2', text: '50'),
            QuestionOption(id: 'o3', text: '43'),
            QuestionOption(id: 'o4', text: '180'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(quiz: quiz, variant: variant);
    final solutionsXml = service.buildSolutionsDocumentXmlForTest(quiz: quiz, variant: variant);

    expect(quizXml, contains('<w:tbl>'));
    expect(quizXml, contains('Variant: V1'));
    expect(quizXml, contains('Triangle angle'));

    expect(solutionsXml, contains('<w:tbl>'));
    expect(solutionsXml, contains('Answer Key'));
    expect(solutionsXml, contains('80'));
  });

  test('adds teacher and school names to quiz header when provided', () {
    final quiz = QuizModel.empty('Geometry');
    final variant = GeneratedVariant(
      id: 'V1',
      quizId: quiz.id,
      seed: 1,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'Triangle angle',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: '80'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      teacherName: 'Ms. Jane',
      schoolName: 'Sunrise School',
    );

    expect(quizXml, contains('Teacher: Ms. Jane'));
    expect(quizXml, contains('School: Sunrise School'));
  });

  test('strips invalid xml control characters from generated document xml', () {
    final quiz = QuizModel.empty('Science\u0001Quiz');
    final variant = GeneratedVariant(
      id: 'V1',
      quizId: quiz.id,
      seed: 2,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'What is H\u0002O?',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: [
            QuestionOption(id: 'o1', text: 'Water'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(quiz: quiz, variant: variant);

    expect(quizXml, isNot(contains('\u0001')));
    expect(quizXml, isNot(contains('\u0002')));
    expect(quizXml, contains('ScienceQuiz'));
    expect(quizXml, contains('What is HO?'));
  });

  test('injects math as raw OMML XML in cell paragraph', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V2',
      quizId: quiz.id,
      seed: 3,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'Compute',
          math: r'\frac{1}{2}',
          imageRef: '',
          correctOptionId: 'o1',
          options: [
            QuestionOption(id: 'o1', text: 'Answer', math: r'\sqrt{4}'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(quiz: quiz, variant: variant);

    expect(quizXml, contains('xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"'));
    expect(quizXml, contains('<m:oMath>'));
    expect(quizXml, contains('(1)/(2)'));
    expect(quizXml, isNot(contains('&lt;m:oMath&gt;')));
  });

  test('normalizes inline $$math$$ in text for export without raw delimiters', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V3',
      quizId: quiz.id,
      seed: 4,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: r'Find sin(x) $$\frac{1}{x}$$',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: r'$$\sqrt{4}$$'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(quiz: quiz, variant: variant);

    expect(quizXml, contains('Find sin(x) (1)/(x)'));
    expect(quizXml, contains('√(4)'));
    expect(quizXml, isNot(contains(r'$$')));
  });

  test('normalizes escaped inline \\$\\$math\\$\\$ delimiters for export', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V4',
      quizId: quiz.id,
      seed: 5,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: r'Find sin(x) \$\$\frac{1}{x}\$\$',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: r'\$\$\sqrt{4}\$\$'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(quiz: quiz, variant: variant);

    expect(quizXml, contains('Find sin(x) (1)/(x)'));
    expect(quizXml, contains('√(4)'));
    expect(quizXml, isNot(contains(r'\$\$')));
  });

  test('builds export filenames with quiz name, version, variant and type', () {
    final quiz = QuizModel.empty('Algebra Final Exam');
    final versionedQuiz = quiz.copyWith(version: 7);
    final variant = GeneratedVariant(
      id: 'V2',
      quizId: quiz.id,
      seed: 6,
      generatedAt: DateTime(2026),
      questions: const [],
    );
    final service = const DocxExportService();

    final questionsName = service.buildExportFileNameForTest(
      quiz: versionedQuiz,
      variant: variant,
      exportType: 'questions',
    );
    final answersName = service.buildExportFileNameForTest(
      quiz: versionedQuiz,
      variant: variant,
      exportType: 'answers',
    );

    expect(questionsName, 'algebra_final_exam_v7_v2_questions.docx');
    expect(answersName, 'algebra_final_exam_v7_v2_answers.docx');
  });
}
