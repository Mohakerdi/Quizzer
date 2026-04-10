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
    expect(solutionsXml, contains('Correct Answer'));
    expect(solutionsXml, contains('80'));
  });
}
