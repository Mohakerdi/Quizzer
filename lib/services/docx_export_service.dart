import 'dart:convert';
import 'dart:io';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DocxExportService {
  const DocxExportService();

  Future<String> exportQuizPaper({
    required QuizModel quiz,
    required GeneratedVariant variant,
  }) async {
    final content = buildQuizDocumentXmlForTest(quiz: quiz, variant: variant);
    return _writeDocx('quiz_${quiz.id}_${variant.id}.docx', content);
  }

  Future<String> exportSolutions({
    required QuizModel quiz,
    required GeneratedVariant variant,
  }) async {
    final content = buildSolutionsDocumentXmlForTest(quiz: quiz, variant: variant);
    return _writeDocx('solutions_${quiz.id}_${variant.id}.docx', content);
  }

  Future<String> _writeDocx(String fileName, String documentXml) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';

    final archive = Archive()
      ..addFile(ArchiveFile('[Content_Types].xml', _contentTypes.length, utf8.encode(_contentTypes)))
      ..addFile(ArchiveFile('_rels/.rels', _rels.length, utf8.encode(_rels)))
      ..addFile(
        ArchiveFile('word/_rels/document.xml.rels', _docRels.length, utf8.encode(_docRels)),
      )
      ..addFile(ArchiveFile('word/document.xml', documentXml.length, utf8.encode(documentXml)));

    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    if (bytes == null) {
      throw Exception('Failed to encode DOCX file.');
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @visibleForTesting
  String buildQuizDocumentXmlForTest({
    required QuizModel quiz,
    required GeneratedVariant variant,
  }) {
    final rows = <String>[
      _row([_escape('Quiz: ${quiz.title}'), _escape('Variant: ${variant.id}'), _escape('Questions: ${variant.questions.length}'), _escape('')]),
    ];

    for (var i = 0; i < variant.questions.length; i++) {
      final question = variant.questions[i];
      rows.add(
        _row([
          _escape('Q${i + 1}'),
          _escape(question.composedPrompt),
          _escape(question.imageRef.isEmpty ? '' : 'Image: ${question.imageRef}'),
          _escape(''),
        ]),
      );

      final optionTexts = question.options.map((o) => o.composedText).toList();
      while (optionTexts.length < 4) {
        optionTexts.add('');
      }
      rows.add(_row(optionTexts.take(4).map(_escape).toList()));
    }

    return _documentTemplate(rows.join());
  }

  @visibleForTesting
  String buildSolutionsDocumentXmlForTest({
    required QuizModel quiz,
    required GeneratedVariant variant,
  }) {
    final rows = <String>[
      _row([_escape('Solutions: ${quiz.title}'), _escape('Variant: ${variant.id}'), '', '']),
      _row([_escape('Question'), _escape('Correct Option ID'), _escape('Correct Answer'), _escape('')]),
    ];

    for (var i = 0; i < variant.questions.length; i++) {
      final question = variant.questions[i];
      final correct = question.options.firstWhere(
        (o) => o.id == question.correctOptionId,
        orElse: () => question.options.first,
      );

      rows.add(
        _row([
          _escape('Q${i + 1}'),
          _escape(correct.id),
          _escape(correct.composedText),
          _escape(question.composedPrompt),
        ]),
      );
    }

    return _documentTemplate(rows.join());
  }

  String _documentTemplate(String rows) {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:tbl>
      $rows
    </w:tbl>
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  String _row(List<String> cols) {
    final cells = cols
        .map(
          (col) => '''<w:tc>
  <w:tcPr><w:tcW w:w="2500" w:type="dxa"/></w:tcPr>
  <w:p><w:r><w:t xml:space="preserve">$col</w:t></w:r></w:p>
</w:tc>''',
        )
        .join();

    return '<w:tr>$cells</w:tr>';
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

const _contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

const _rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

const _docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';
