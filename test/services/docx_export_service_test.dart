import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/services/docx_export_service.dart';
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
    expect(quizXml, contains('Question Paper: Geometry'));
    expect(quizXml, contains('Variant: V1'));
    expect(quizXml, contains('Triangle angle'));

    expect(solutionsXml, contains('<w:tbl>'));
    expect(solutionsXml, contains('Answer Key'));
    expect(solutionsXml, contains('80'));
  });

  test('uses fixed in-bounds table width for exported DOCX', () {
    final quiz = QuizModel.empty('Geometry');
    final variant = GeneratedVariant(
      id: 'V1',
      quizId: quiz.id,
      seed: 1,
      generatedAt: DateTime(2026),
      questions: const [],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(quiz: quiz, variant: variant);

    expect(quizXml, contains('<w:tblW w:w="10706" w:type="dxa"/>'));
    expect(quizXml, contains('<w:gridCol w:w="1200"/>'));
    expect(quizXml, contains('<w:gridCol w:w="3168"/>'));
    expect(quizXml, contains('<w:gridCol w:w="3170"/>'));
  });

  test('uses arabic option labels when arabic label style is selected', () {
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
            QuestionOption(id: 'o2', text: '50'),
            QuestionOption(id: 'o3', text: '43'),
            QuestionOption(id: 'o4', text: '180'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: 'ar',
      optionLabelStyle: 'arabic',
    );

    expect(quizXml, contains('أ) 80'));
    expect(quizXml, contains('ب) 50'));
    expect(quizXml, contains('ج) 43'));
    expect(quizXml, contains('د) 180'));
    expect(quizXml, isNot(contains('A) 80')));
  });

  test('flips table cell order for arabic export RTL layout', () {
    final quiz = QuizModel.empty('اختبار');
    final variant = GeneratedVariant(
      id: 'V1',
      quizId: quiz.id,
      seed: 1,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'نص السؤال',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: 'الخيار الأول'),
            QuestionOption(id: 'o2', text: 'الخيار الثاني'),
            QuestionOption(id: 'o3', text: 'الخيار الثالث'),
            QuestionOption(id: 'o4', text: 'الخيار الرابع'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: 'ar',
      optionLabelStyle: 'arabic',
    );

    expect(quizXml.indexOf('التاريخ:'), lessThan(quizXml.indexOf('الاختبار:')));
    expect(quizXml.indexOf('د) الخيار الرابع'), lessThan(quizXml.indexOf('أ) الخيار الأول')));
  });

  test('aligns arabic export text to right and english export text to left', () {
    final quiz = QuizModel.empty('Language');
    final variant = GeneratedVariant(
      id: 'V1',
      quizId: quiz.id,
      seed: 1,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'مرحبا',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: 'الخيار الأول'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final arabicXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: 'ar',
      optionLabelStyle: 'arabic',
    );
    final englishXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: 'en',
      optionLabelStyle: 'latin',
    );

    expect(arabicXml, contains('<w:pPr><w:bidi/><w:jc w:val="right"/></w:pPr>'));
    expect(arabicXml, contains('<w:rPr><w:rtl/></w:rPr>'));
    expect(englishXml, contains('<w:pPr><w:jc w:val="left"/></w:pPr>'));
    expect(
      arabicXml,
      contains('<w:p><w:pPr><w:bidi/><w:jc w:val="right"/></w:pPr><w:r><w:t xml:space="preserve"> </w:t></w:r></w:p>'),
    );
  });

  test('keeps english export table ordering LTR even with arabic content', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V1',
      quizId: quiz.id,
      seed: 1,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'نص السؤال',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: 'الخيار الأول'),
            QuestionOption(id: 'o2', text: 'الخيار الثاني'),
            QuestionOption(id: 'o3', text: 'الخيار الثالث'),
            QuestionOption(id: 'o4', text: 'الخيار الرابع'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: 'en',
      optionLabelStyle: 'latin',
    );

    expect(quizXml, contains('<w:pPr><w:jc w:val="left"/></w:pPr>'));
    expect(quizXml.indexOf('Q1'), lessThan(quizXml.indexOf('نص السؤال')));
    expect(quizXml.indexOf('A) الخيار الأول'), lessThan(quizXml.indexOf('D) الخيار الرابع')));
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

  test('renders arabic export headings when arabic export language is selected', () {
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
      exportLanguageCode: 'ar',
    );
    final solutionsXml = service.buildSolutionsDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: 'ar',
    );

    expect(quizXml, contains('ورقة الأسئلة'));
    expect(quizXml, contains('ورقة الأسئلة: Geometry'));
    expect(quizXml, contains('الاختبار: Geometry'));
    expect(quizXml, contains('المعلم: Ms. Jane'));
    expect(quizXml, contains('المدرسة: Sunrise School'));
    expect(solutionsXml, contains('مفتاح الإجابة'));
    expect(solutionsXml, contains('الحلول: Geometry'));
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

  test('exports legacy math fields as normalized plain text', () {
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
    final solutionsXml = service.buildSolutionsDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
    );

    expect(quizXml, isNot(contains('<m:oMath>')));
    expect(solutionsXml, isNot(contains('<m:oMath>')));
    expect(quizXml, contains('(1)/(2)'));
    expect(quizXml, contains('√(4)'));
    expect(solutionsXml, contains('(1)/(2)'));
    expect(solutionsXml, contains('√(4)'));
  });

  test('renders legacy answer math fields as Word equations when enabled', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V7',
      quizId: quiz.id,
      seed: 8,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'Compute',
          math: r'\frac{1}{2}',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: 'Answer', math: r'x^2 + \pi'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final solutionsXml = service.buildSolutionsDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      renderEquationsAsWordMath: true,
    );

    expect('<m:oMath>'.allMatches(solutionsXml).length, equals(2));
    expect(solutionsXml, contains('<m:f><m:num><m:r><m:t>1</m:t></m:r></m:num><m:den><m:r><m:t>2</m:t></m:r></m:den></m:f>'));
    expect(solutionsXml, contains('<m:sSup><m:e><m:r><m:t>x</m:t></m:r></m:e><m:sup><m:r><m:t>2</m:t></m:r></m:sup></m:sSup>'));
    expect(solutionsXml, contains('<m:r><m:t>π</m:t></m:r>'));
  });

  test('renders latex-like imported option text as Word equation in solutions export', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V8',
      quizId: quiz.id,
      seed: 9,
      generatedAt: DateTime(2026),
      questions: const [
        GeneratedQuestion(
          questionId: 'q1',
          text: 'Compute',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: [
            QuestionOption(id: 'o1', text: r'\frac{1}{2}'),
            QuestionOption(id: 'o2', text: 'regular'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final solutionsXml = service.buildSolutionsDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      renderEquationsAsWordMath: true,
    );

    expect(solutionsXml, contains('<m:oMath>'));
    expect(solutionsXml, contains('<m:f><m:num><m:r><m:t>1</m:t></m:r></m:num><m:den><m:r><m:t>2</m:t></m:r></m:den></m:f>'));
    expect(solutionsXml, isNot(contains(r'\frac{1}{2}')));
  });

  test('exports inline $$math$$ in text as normalized plain text', () {
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

    expect(quizXml, contains('Find sin(x)'));
    expect(quizXml, contains('(1)/(x)'));
    expect(quizXml, contains('√(4)'));
    expect(quizXml, isNot(contains('<m:oMath>')));
    expect(quizXml, isNot(contains(r'$$')));
  });

  test('exports escaped inline \\$\\$math\\$\\$ delimiters as plain text', () {
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

    expect(quizXml, contains('Find sin(x)'));
    expect(quizXml, contains('(1)/(x)'));
    expect(quizXml, contains('√(4)'));
    expect(quizXml, isNot(contains('<m:oMath>')));
    expect(quizXml, isNot(contains(r'\$\$')));
  });

  test('exports multiple inline equations as normalized plain text', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V5',
      quizId: quiz.id,
      seed: 6,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: r'Compute $$\frac{1}{2}$$ then $$\sqrt{9}$$',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: r'$$x^2$$ and $$\pi$$'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(quiz: quiz, variant: variant);

    expect('<m:oMath>'.allMatches(quizXml).length, equals(0));
    expect(quizXml, contains('(1)/(2)'));
    expect(quizXml, contains('√(9)'));
    expect(quizXml, contains('x²'));
    expect(quizXml, contains('π'));
    expect(quizXml, isNot(contains(r'$$')));
  });

  test('renders inline $$math$$ as Word equation objects when enabled', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V5',
      quizId: quiz.id,
      seed: 6,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: r'Compute $$\frac{1}{2}$$ then $$\sqrt{9}$$',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: r'$$x^2$$ and $$\pi$$'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      renderEquationsAsWordMath: true,
    );

    expect('<m:oMath>'.allMatches(quizXml).length, equals(4));
    expect(quizXml, contains('<m:f><m:num><m:r><m:t>1</m:t></m:r></m:num><m:den><m:r><m:t>2</m:t></m:r></m:den></m:f>'));
    expect(quizXml, contains('<m:rad><m:radPr><m:degHide m:val="1"/></m:radPr><m:e><m:r><m:t>9</m:t></m:r></m:e></m:rad>'));
    expect(quizXml, contains('<m:sSup><m:e><m:r><m:t>x</m:t></m:r></m:e><m:sup><m:r><m:t>2</m:t></m:r></m:sup></m:sSup>'));
    expect(quizXml, contains('<m:r><m:t>π</m:t></m:r>'));
    expect(quizXml, isNot(contains('{{EQ:')));
  });

  test('renders matrix and n-ary equations as structured OMML when enabled', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V6',
      quizId: quiz.id,
      seed: 7,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: r'Compute $$\begin{matrix}a & b\\c & d\end{matrix}$$',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: r'$$\sum_{i=1}^{n}{x_i}$$'),
            QuestionOption(id: 'o2', text: r'$$\int_{0}^{1}{x}$$'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      renderEquationsAsWordMath: true,
    );

    expect(quizXml, contains('<m:m><m:mPr/>'));
    expect('<m:mr>'.allMatches(quizXml).length, equals(2));
    expect(quizXml, contains('<m:nary><m:naryPr><m:chr m:val="∑"/></m:naryPr>'));
    expect(quizXml, contains('<m:nary><m:naryPr><m:chr m:val="∫"/></m:naryPr>'));
  });

  test('normalizes indexed roots in inline equations for export', () {
    final quiz = QuizModel.empty('Math');
    final variant = GeneratedVariant(
      id: 'V6',
      quizId: quiz.id,
      seed: 7,
      generatedAt: DateTime(2026),
      questions: [
        GeneratedQuestion(
          questionId: 'q1',
          text: r'ما الحل إذا علمت أن $$\sqrt[3]{x} = \frac{4}{2}$$',
          math: '',
          imageRef: '',
          correctOptionId: 'o1',
          options: const [
            QuestionOption(id: 'o1', text: r'$$\sqrt[12]{y}$$'),
          ],
        ),
      ],
    );

    final service = const DocxExportService();
    final quizXml = service.buildQuizDocumentXmlForTest(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: 'ar',
    );

    expect(quizXml, contains('³√(x) = (4)/(2)'));
    expect(quizXml, contains('¹²√(y)'));
    expect(quizXml, isNot(contains(r'sqrt[3]{x}')));
    expect(quizXml, isNot(contains(r'$$')));
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

    expect(questionsName, 'algebra_final_exam_v7_v2_quiz.docx');
    expect(answersName, 'algebra_final_exam_v7_v2_answer.docx');
  });

  test('builds anchored square-wrapped image drawing XML for DOCX export', () {
    final service = const DocxExportService();
    final xml = service.buildImageDrawingXmlForTest('rIdImage3');

    expect(xml, contains('<wp:anchor'));
    expect(xml, contains('<wp:wrapSquare wrapText="bothSides"/>'));
    expect(xml, isNot(contains('<wp:inline')));
    expect(xml, contains('<a:blip r:embed="rIdImage3"/>'));
  });
}
