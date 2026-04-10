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
      ..addFile(ArchiveFile('word/_rels/document.xml.rels', _docRels.length, utf8.encode(_docRels)))
      ..addFile(ArchiveFile('word/document.xml', documentXml.length, utf8.encode(documentXml)))
      ..addFile(ArchiveFile('word/styles.xml', _styles.length, utf8.encode(_styles)));

    final bytes = ZipEncoder().encode(archive);
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
    final isRtl = _containsArabic(
      [
        quiz.title,
        ...variant.questions.map((q) => q.composedPrompt),
        ...variant.questions.expand((q) => q.options.map((o) => o.composedText)),
      ].join(' '),
    );
    final rows = <String>[
      _headerRow([
        'Quiz: ${quiz.title}',
        'Variant: ${variant.id}',
        'Questions: ${variant.questions.length}',
        'Date: ${variant.generatedAt.toIso8601String().split('T').first}',
      ]),
    ];

    for (var i = 0; i < variant.questions.length; i++) {
      final question = variant.questions[i];
      final prompt = StringBuffer(question.composedPrompt);
      if (question.imageRef.trim().isNotEmpty) {
        prompt.write('\n[Image: ${question.imageRef.trim()}]');
      }

      rows.add(
        _row(
          [
            _cell('Q${i + 1}', bold: true, align: 'center', rtl: isRtl),
            _cell(prompt.toString(), colSpan: 3, rtl: isRtl),
          ],
        ),
      );

      final labels = ['A', 'B', 'C', 'D'];
      final optionCells = List.generate(4, (index) {
        if (index >= question.options.length) {
          return _cell('', rtl: isRtl);
        }
        final text = '${labels[index]}) ${question.options[index].composedText}';
        return _cell(text, rtl: isRtl);
      });

      rows.add(_row(optionCells));
    }

    return _documentTemplate(
      title: 'Question Paper',
      body: _table(rows.join()),
      rtl: isRtl,
    );
  }

  @visibleForTesting
  String buildSolutionsDocumentXmlForTest({
    required QuizModel quiz,
    required GeneratedVariant variant,
  }) {
    final isRtl = _containsArabic(
      [
        quiz.title,
        ...variant.questions.map((q) => q.composedPrompt),
        ...variant.questions.expand((q) => q.options.map((o) => o.composedText)),
      ].join(' '),
    );
    final rows = <String>[
      _headerRow([
        'Solutions: ${quiz.title}',
        'Variant: ${variant.id}',
        'Total: ${variant.questions.length}',
        '',
      ]),
      _row([
        _cell('Q#', bold: true, align: 'center', rtl: isRtl),
        _cell('Correct Option', bold: true, align: 'center', rtl: isRtl),
        _cell('Correct Answer', bold: true, rtl: isRtl),
        _cell('Question', bold: true, rtl: isRtl),
      ]),
    ];

    for (var i = 0; i < variant.questions.length; i++) {
      final question = variant.questions[i];
      final options = question.options;
      final correctIndex = options.indexWhere((o) => o.id == question.correctOptionId);
      final resolvedIndex = correctIndex < 0 ? 0 : correctIndex;
      final correct = options.isNotEmpty ? options[resolvedIndex] : null;
      final optionLetter = ['A', 'B', 'C', 'D'];
      final letter = resolvedIndex < optionLetter.length ? optionLetter[resolvedIndex] : '#${resolvedIndex + 1}';

      rows.add(
        _row([
          _cell('${i + 1}', align: 'center', rtl: isRtl),
          _cell(letter, align: 'center', bold: true, rtl: isRtl),
          _cell(correct?.composedText ?? '-', rtl: isRtl),
          _cell(question.composedPrompt, rtl: isRtl),
        ]),
      );
    }

    return _documentTemplate(
      title: 'Answer Key',
      body: _table(rows.join()),
      rtl: isRtl,
    );
  }

  String _documentTemplate({required String title, required String body, required bool rtl}) {
    final bidi = rtl ? '<w:bidi/>' : '';
    final jc = rtl ? 'right' : 'center';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr>$bidi<w:jc w:val="$jc"/></w:pPr>
      <w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>${_escape(title)}</w:t></w:r>
    </w:p>
    <w:p><w:r><w:t xml:space="preserve"> </w:t></w:r></w:p>
    $body
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="600" w:right="600" w:bottom="600" w:left="600"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  String _table(String rows) {
    return '''<w:tbl>
  <w:tblPr>
    <w:tblW w:w="0" w:type="auto"/>
    <w:tblLayout w:type="fixed"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="12"/>
      <w:left w:val="single" w:sz="12"/>
      <w:bottom w:val="single" w:sz="12"/>
      <w:right w:val="single" w:sz="12"/>
      <w:insideH w:val="single" w:sz="8"/>
      <w:insideV w:val="single" w:sz="8"/>
    </w:tblBorders>
  </w:tblPr>
  <w:tblGrid>
    <w:gridCol w:w="1400"/>
    <w:gridCol w:w="3300"/>
    <w:gridCol w:w="3300"/>
    <w:gridCol w:w="3300"/>
  </w:tblGrid>
  $rows
</w:tbl>''';
  }

  String _headerRow(List<String> values) {
    final cells = values
        .map(
          (value) => _cell(
            value,
            bold: true,
            align: 'center',
            shaded: true,
          ),
        )
        .toList();
    return _row(cells);
  }

  String _row(List<String> cells) => '<w:tr>${cells.join()}</w:tr>';

  String _cell(
    String text, {
    int colSpan = 1,
    bool bold = false,
    bool shaded = false,
    String align = 'left',
    bool rtl = false,
  }) {
    final merged = colSpan > 1 ? '<w:gridSpan w:val="$colSpan"/>' : '';
    final shading = shaded ? '<w:shd w:val="clear" w:fill="EDEDED"/>' : '';
    final fallbackAlign = rtl ? 'right' : 'left';
    final effectiveAlign = align == 'left' ? fallbackAlign : align;
    final jc = effectiveAlign == 'center' ? 'center' : (effectiveAlign == 'right' ? 'right' : 'left');
    final runs = _paragraphRuns(text, bold: bold);
    final bidi = rtl ? '<w:bidi/>' : '';

    return '''<w:tc>
  <w:tcPr>
    <w:tcW w:w="0" w:type="auto"/>
    $merged
    $shading
    <w:vAlign w:val="center"/>
    <w:tcMar>
      <w:top w:w="80" w:type="dxa"/>
      <w:left w:w="120" w:type="dxa"/>
      <w:bottom w:w="80" w:type="dxa"/>
      <w:right w:w="120" w:type="dxa"/>
    </w:tcMar>
  </w:tcPr>
  <w:p>
    <w:pPr>$bidi<w:jc w:val="$jc"/></w:pPr>
    $runs
  </w:p>
</w:tc>''';
  }

  String _paragraphRuns(String text, {required bool bold}) {
    final escapedLines = _escape(text).split('\n');
    final buffer = StringBuffer();
    for (var i = 0; i < escapedLines.length; i++) {
      final line = escapedLines[i];
      buffer.write('<w:r>');
      if (bold) {
        buffer.write('<w:rPr><w:b/></w:rPr>');
      }
      buffer.write('<w:t xml:space="preserve">${line.isEmpty ? ' ' : line}</w:t>');
      buffer.write('</w:r>');
      if (i < escapedLines.length - 1) {
        buffer.write('<w:r><w:br/></w:r>');
      }
    }
    return buffer.toString();
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  bool _containsArabic(String value) {
    final arabicRange = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRange.hasMatch(value);
  }
}

const _contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

const _rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

const _docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

const _styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Calibri" w:cs="Calibri"/>
        <w:sz w:val="22"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';
