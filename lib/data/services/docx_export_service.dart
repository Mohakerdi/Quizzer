import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/core/utils/friendly_math_formatter.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DocxExportService {
  const DocxExportService();
  static const int _pageWidthTwips = 11906;
  static const int _pageHeightTwips = 16838;
  static const int _pageMarginTwips = 600;
  static const int _tableTotalWidthTwips = _pageWidthTwips - (_pageMarginTwips * 2); // 10706
  static const int _firstColumnWidthTwips = 1200;
  static const int _secondColumnWidthTwips = 3168;
  static const int _thirdColumnWidthTwips = 3168;
  // Kept 2 twips wider so all 4 columns sum exactly to _tableTotalWidthTwips.
  static const int _fourthColumnWidthTwips = 3170;

  Future<String> exportQuizPaper({
    required QuizModel quiz,
    required GeneratedVariant variant,
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
  }) async {
    final imageAssetsByQuestion = await _prepareImageAssets(variant.questions);
    final equationRegistry = _EquationAssetRegistry();
    final content = _buildQuizDocumentXml(
      quiz: quiz,
      variant: variant,
      teacherName: teacherName,
      schoolName: schoolName,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
      imageAssetsByQuestion: imageAssetsByQuestion,
      includeImagePathFallback: true,
      equationRegistry: equationRegistry,
      renderEquationsAsWordMath: true,
    );
    return _writeDocx(
      _buildExportFileName(
        quiz: quiz,
        variant: variant,
        exportType: 'quiz',
      ),
      content,
      imageAssets: [...imageAssetsByQuestion.values],
    );
  }

  Future<String> exportSolutions({
    required QuizModel quiz,
    required GeneratedVariant variant,
    String? exportLanguageCode,
    String? optionLabelStyle,
  }) async {
    final imageAssetsByQuestion = await _prepareImageAssets(variant.questions);
    final equationRegistry = _EquationAssetRegistry();
    final content = _buildSolutionsDocumentXml(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
      imageAssetsByQuestion: imageAssetsByQuestion,
      includeImagePathFallback: true,
      equationRegistry: equationRegistry,
      renderEquationsAsWordMath: true,
    );
    return _writeDocx(
      _buildExportFileName(
        quiz: quiz,
        variant: variant,
        exportType: 'answer',
      ),
      content,
      imageAssets: [...imageAssetsByQuestion.values],
    );
  }

  Future<String> _writeDocx(
    String fileName,
    String documentXml, {
    List<_EmbeddedImageAsset> imageAssets = const [],
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';
    final contentTypesBytes = utf8.encode(_buildContentTypes(imageAssets));
    final relsBytes = utf8.encode(_rels);
    final docRelsBytes = utf8.encode(_buildDocRels(imageAssets));
    final documentBytes = utf8.encode(documentXml);
    final stylesBytes = utf8.encode(_styles);

    final archive = Archive()
      ..addFile(ArchiveFile('[Content_Types].xml', contentTypesBytes.length, contentTypesBytes))
      ..addFile(ArchiveFile('_rels/.rels', relsBytes.length, relsBytes))
      ..addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsBytes.length, docRelsBytes))
      ..addFile(ArchiveFile('word/document.xml', documentBytes.length, documentBytes))
      ..addFile(ArchiveFile('word/styles.xml', stylesBytes.length, stylesBytes));
    for (final imageAsset in imageAssets) {
      archive.addFile(
        ArchiveFile(
          'word/${imageAsset.targetPath}',
          imageAsset.bytes.length,
          imageAsset.bytes,
        ),
      );
    }

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
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
    bool renderEquationsAsWordMath = false,
  }) {
    final equationRegistry = _EquationAssetRegistry();
    return _buildQuizDocumentXml(
      quiz: quiz,
      variant: variant,
      teacherName: teacherName,
      schoolName: schoolName,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
      imageAssetsByQuestion: const {},
      includeImagePathFallback: true,
      equationRegistry: equationRegistry,
      renderEquationsAsWordMath: renderEquationsAsWordMath,
    );
  }

  @visibleForTesting
  String buildExportFileNameForTest({
    required QuizModel quiz,
    required GeneratedVariant variant,
    required String exportType,
  }) {
    return _buildExportFileName(
      quiz: quiz,
      variant: variant,
      exportType: exportType,
    );
  }

  String _buildExportFileName({
    required QuizModel quiz,
    required GeneratedVariant variant,
    required String exportType,
  }) {
    final quizName = _sanitizeFileNameSegment(quiz.title);
    final version = 'v${quiz.version}';
    final variantId = _sanitizeFileNameSegment(variant.id);
    return '${quizName}_${version}_${variantId}_$exportType.docx';
  }

  String _sanitizeFileNameSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final replaced = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final collapsed = replaced.replaceAll(RegExp(r'_+'), '_');
    final cleaned = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'quiz' : cleaned;
  }

  String _buildQuizDocumentXml({
    required QuizModel quiz,
    required GeneratedVariant variant,
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
    required Map<int, _EmbeddedImageAsset> imageAssetsByQuestion,
    required bool includeImagePathFallback,
    required _EquationAssetRegistry equationRegistry,
    required bool renderEquationsAsWordMath,
  }) {
    final exportInArabic = _isArabicLanguageCode(exportLanguageCode);
    final isRtl = exportInArabic || _containsArabic(
      [
        quiz.title,
        ...variant.questions.map((q) => _composeForExport(text: q.text, math: q.math)),
        ...variant.questions.expand((q) => q.options.map((o) => _composeForExport(text: o.text, math: o.math))),
      ].join(' '),
    );
    final rows = <String>[
      _headerRow([
        '${exportInArabic ? 'الاختبار' : 'Quiz'}: ${quiz.title}',
        '${exportInArabic ? 'النموذج' : 'Variant'}: ${variant.id}',
        '${exportInArabic ? 'الأسئلة' : 'Questions'}: ${variant.questions.length}',
        '${exportInArabic ? 'التاريخ' : 'Date'}: ${variant.generatedAt.toIso8601String().split('T').first}',
      ], rtl: isRtl),
    ];
    final normalizedTeacher = teacherName?.trim() ?? '';
    final normalizedSchool = schoolName?.trim() ?? '';
    if (normalizedTeacher.isNotEmpty || normalizedSchool.isNotEmpty) {
      const additionalEmptyCells = ['', ''];
      rows.add(
        _headerRow([
          normalizedTeacher.isEmpty ? '' : '${exportInArabic ? 'المعلم' : 'Teacher'}: $normalizedTeacher',
          normalizedSchool.isEmpty ? '' : '${exportInArabic ? 'المدرسة' : 'School'}: $normalizedSchool',
          ...additionalEmptyCells,
        ], rtl: isRtl),
      );
    }

    for (var i = 0; i < variant.questions.length; i++) {
      final question = variant.questions[i];
      final imageAsset = imageAssetsByQuestion[i];
      final promptSource = renderEquationsAsWordMath
          ? _composeRawForWordMath(text: question.text, math: question.math)
          : _composeForExport(text: question.text, math: question.math);
      final encodedPrompt = renderEquationsAsWordMath
          ? equationRegistry.encodeText(
              promptSource,
              keyPrefix: 'q_${i}_prompt',
            )
          : promptSource;
      final prompt = StringBuffer(
        renderEquationsAsWordMath ? _normalizeTextForExport(encodedPrompt) : encodedPrompt,
      );
      if (imageAsset == null && includeImagePathFallback && question.imageRef.trim().isNotEmpty) {
        prompt.write('\n[${exportInArabic ? 'صورة' : 'Image'}: ${question.imageRef.trim()}]');
      }

      rows.add(
        _row(
          _maybeFlipCellsForRtl([
            _cell('Q${i + 1}', bold: true, align: 'center', rtl: isRtl),
            _cell(
              prompt.toString(),
              colSpan: 3,
              rtl: isRtl,
              imageRelationshipId: imageAsset?.relationshipId,
              equationTextByToken: equationRegistry.textByToken,
            ),
          ], isRtl),
        ),
      );

      final labels = _resolveOptionLabels(
        optionLabelStyle: optionLabelStyle,
        exportInArabic: exportInArabic,
      );
      final optionCells = List.generate(4, (index) {
        if (index >= question.options.length) {
          return _cell('', rtl: isRtl);
        }
        final option = question.options[index];
        final optionBody = renderEquationsAsWordMath
            ? _composeRawForWordMath(text: option.text, math: option.math)
            : _composeForExport(text: option.text, math: option.math);
        final optionContent = optionBody.isEmpty ? '${labels[index]})' : '${labels[index]}) $optionBody';
        final encodedOption = renderEquationsAsWordMath
            ? equationRegistry.encodeText(optionContent, keyPrefix: 'q_${i}_option_$index')
            : optionContent;
        return _cell(
          renderEquationsAsWordMath ? _normalizeTextForExport(encodedOption) : encodedOption,
          rtl: isRtl,
          equationTextByToken: equationRegistry.textByToken,
        );
      });

      rows.add(_row(_maybeFlipCellsForRtl(optionCells, isRtl)));
    }

    return _documentTemplate(
      title: exportInArabic ? 'ورقة الأسئلة: ${quiz.title}' : 'Question Paper: ${quiz.title}',
      body: _table(rows.join()),
      rtl: isRtl,
    );
  }

  @visibleForTesting
  String buildSolutionsDocumentXmlForTest({
    required QuizModel quiz,
    required GeneratedVariant variant,
    String? exportLanguageCode,
    String? optionLabelStyle,
    bool renderEquationsAsWordMath = false,
  }) {
    final equationRegistry = _EquationAssetRegistry();
    return _buildSolutionsDocumentXml(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
      imageAssetsByQuestion: const {},
      includeImagePathFallback: true,
      equationRegistry: equationRegistry,
      renderEquationsAsWordMath: renderEquationsAsWordMath,
    );
  }

  String _buildSolutionsDocumentXml({
    required QuizModel quiz,
    required GeneratedVariant variant,
    String? exportLanguageCode,
    String? optionLabelStyle,
    required Map<int, _EmbeddedImageAsset> imageAssetsByQuestion,
    required bool includeImagePathFallback,
    required _EquationAssetRegistry equationRegistry,
    required bool renderEquationsAsWordMath,
  }) {
    final exportInArabic = _isArabicLanguageCode(exportLanguageCode);
    final isRtl = exportInArabic || _containsArabic(
      [
        quiz.title,
        ...variant.questions.map((q) => _composeForExport(text: q.text, math: q.math)),
        ...variant.questions.expand((q) => q.options.map((o) => _composeForExport(text: o.text, math: o.math))),
      ].join(' '),
    );
    final rows = <String>[
      _headerRow([
        '${exportInArabic ? 'الحلول' : 'Solutions'}: ${quiz.title}',
        '${exportInArabic ? 'النموذج' : 'Variant'}: ${variant.id}',
        '${exportInArabic ? 'الأسئلة' : 'Questions'}: ${variant.questions.length}',
        '',
      ], rtl: isRtl),
    ];

    for (var i = 0; i < variant.questions.length; i++) {
      final question = variant.questions[i];
      final imageAsset = imageAssetsByQuestion[i];
      final promptSource = renderEquationsAsWordMath
          ? _composeRawForWordMath(text: question.text, math: question.math)
          : _composeForExport(text: question.text, math: question.math);
      final encodedPrompt = renderEquationsAsWordMath
          ? equationRegistry.encodeText(
              promptSource,
              keyPrefix: 'a_${i}_prompt',
            )
          : promptSource;
      final prompt = StringBuffer(
        renderEquationsAsWordMath ? _normalizeTextForExport(encodedPrompt) : encodedPrompt,
      );
      if (imageAsset == null && includeImagePathFallback && question.imageRef.trim().isNotEmpty) {
        prompt.write('\n[${exportInArabic ? 'صورة' : 'Image'}: ${question.imageRef.trim()}]');
      }

      rows.add(
        _row(
          _maybeFlipCellsForRtl([
            _cell('${i + 1}', align: 'center', rtl: isRtl),
            _cell(
              prompt.toString(),
              colSpan: 3,
              rtl: isRtl,
              imageRelationshipId: imageAsset?.relationshipId,
              equationTextByToken: equationRegistry.textByToken,
            ),
          ], isRtl),
        ),
      );

      final labels = _resolveOptionLabels(
        optionLabelStyle: optionLabelStyle,
        exportInArabic: exportInArabic,
      );
      final optionCells = List.generate(4, (index) {
        if (index >= question.options.length) {
          return _cell('', rtl: isRtl);
        }

        final option = question.options[index];
        final isCorrect = option.id == question.correctOptionId;
        final optionBody = renderEquationsAsWordMath
            ? _composeRawForWordMath(text: option.text, math: option.math)
            : _composeForExport(text: option.text, math: option.math);
        final optionContent = optionBody.isEmpty ? '${labels[index]})' : '${labels[index]}) $optionBody';
        final encodedOption = renderEquationsAsWordMath
            ? equationRegistry.encodeText(optionContent, keyPrefix: 'a_${i}_option_$index')
            : optionContent;
        return _cell(
          renderEquationsAsWordMath ? _normalizeTextForExport(encodedOption) : encodedOption,
          rtl: isRtl,
          bold: isCorrect,
          fillColor: isCorrect ? 'C6EFCE' : null,
          equationTextByToken: equationRegistry.textByToken,
        );
      });

      rows.add(_row(_maybeFlipCellsForRtl(optionCells, isRtl)));
    }

    return _documentTemplate(
      title: exportInArabic ? 'مفتاح الإجابة' : 'Answer Key',
      body: _table(rows.join()),
      rtl: isRtl,
    );
  }

  String _documentTemplate({required String title, required String body, required bool rtl}) {
    final bidi = rtl ? '<w:bidi/>' : '';
    final jc = rtl ? 'right' : 'center';
    final spacerJc = rtl ? 'right' : 'left';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math">
  <w:body>
    <w:p>
      <w:pPr>$bidi<w:jc w:val="$jc"/></w:pPr>
      <w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>${_escape(title)}</w:t></w:r>
    </w:p>
    <w:p><w:pPr>$bidi<w:jc w:val="$spacerJc"/></w:pPr><w:r><w:t xml:space="preserve"> </w:t></w:r></w:p>
    $body
    <w:sectPr>
      <w:pgSz w:w="$_pageWidthTwips" w:h="$_pageHeightTwips"/>
      <w:pgMar w:top="$_pageMarginTwips" w:right="$_pageMarginTwips" w:bottom="$_pageMarginTwips" w:left="$_pageMarginTwips"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  String _table(String rows) {
    return '''<w:tbl>
  <w:tblPr>
    <w:tblW w:w="$_tableTotalWidthTwips" w:type="dxa"/>
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
    <w:gridCol w:w="$_firstColumnWidthTwips"/>
    <w:gridCol w:w="$_secondColumnWidthTwips"/>
    <w:gridCol w:w="$_thirdColumnWidthTwips"/>
    <w:gridCol w:w="$_fourthColumnWidthTwips"/>
  </w:tblGrid>
  $rows
</w:tbl>''';
  }

  String _headerRow(List<String> values, {required bool rtl}) {
    final cells = values
        .map(
          (value) => _cell(
            value,
            bold: true,
            align: 'center',
            fillColor: 'EDEDED',
          ),
        )
        .toList();
    return _row(_maybeFlipCellsForRtl(cells, rtl));
  }

  String _row(List<String> cells) => '<w:tr>${cells.join()}</w:tr>';

  String _cell(
    String text, {
    int colSpan = 1,
    bool bold = false,
    String? fillColor,
    String align = 'left',
    bool rtl = false,
    String? imageRelationshipId,
    Map<String, String> equationTextByToken = const {},
  }) {
    final merged = colSpan > 1 ? '<w:gridSpan w:val="$colSpan"/>' : '';
    final shading = fillColor == null ? '' : '<w:shd w:val="clear" w:fill="$fillColor"/>';
    final fallbackAlign = rtl ? 'right' : 'left';
    final effectiveAlign = align == 'left' ? fallbackAlign : align;
    final jc = effectiveAlign == 'center' ? 'center' : (effectiveAlign == 'right' ? 'right' : 'left');
    final paragraphContent = _buildParagraphContent(
      text,
      bold: bold,
      rtl: rtl,
      equationTextByToken: equationTextByToken,
    );
    final bidi = rtl ? '<w:bidi/>' : '';
    final imageParagraphJc = rtl ? 'right' : 'center';
    final imageParagraph = imageRelationshipId == null
        ? ''
        : '''
  <w:p>
    <w:pPr>$bidi<w:jc w:val="$imageParagraphJc"/></w:pPr>
    <w:r>
      ${_anchoredImageDrawingXml(imageRelationshipId)}
    </w:r>
  </w:p>''';

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
    $paragraphContent
  </w:p>
  $imageParagraph
</w:tc>''';
  }

  String _buildParagraphContent(
    String text, {
    required bool bold,
    required bool rtl,
    required Map<String, String> equationTextByToken,
  }) {
    return _paragraphRuns(
      text,
      bold: bold,
      rtl: rtl,
      equationTextByToken: equationTextByToken,
    );
  }

  @visibleForTesting
  String buildImageDrawingXmlForTest(String relationshipId) {
    return _anchoredImageDrawingXml(relationshipId);
  }

  String _anchoredImageDrawingXml(String relationshipId) {
    const cx = 3600000;
    const cy = 2160000;
    final imageId = int.tryParse(relationshipId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return '''<w:drawing>
  <wp:anchor distT="0" distB="0" distL="114300" distR="114300" simplePos="0" relativeHeight="251658240" behindDoc="0" locked="0" layoutInCell="1" allowOverlap="1">
    <wp:simplePos x="0" y="0"/>
    <wp:positionH relativeFrom="column">
      <wp:posOffset>0</wp:posOffset>
    </wp:positionH>
    <wp:positionV relativeFrom="paragraph">
      <wp:posOffset>0</wp:posOffset>
    </wp:positionV>
    <wp:extent cx="$cx" cy="$cy"/>
    <wp:effectExtent l="0" t="0" r="0" b="0"/>
    <wp:wrapSquare wrapText="bothSides"/>
    <wp:docPr id="$imageId" name="QuestionImage$imageId"/>
    <wp:cNvGraphicFramePr>
      <a:graphicFrameLocks noChangeAspect="1"/>
    </wp:cNvGraphicFramePr>
    <a:graphic>
      <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
        <pic:pic>
          <pic:nvPicPr>
            <pic:cNvPr id="$imageId" name="QuestionImage$imageId"/>
            <pic:cNvPicPr/>
          </pic:nvPicPr>
          <pic:blipFill>
            <a:blip r:embed="$relationshipId"/>
            <a:stretch>
              <a:fillRect/>
            </a:stretch>
          </pic:blipFill>
          <pic:spPr>
            <a:xfrm>
              <a:off x="0" y="0"/>
              <a:ext cx="$cx" cy="$cy"/>
            </a:xfrm>
            <a:prstGeom prst="rect">
              <a:avLst/>
            </a:prstGeom>
          </pic:spPr>
        </pic:pic>
      </a:graphicData>
    </a:graphic>
  </wp:anchor>
</w:drawing>''';
  }

  String _paragraphRuns(
    String text, {
    required bool bold,
    required bool rtl,
    required Map<String, String> equationTextByToken,
  }) {
    final escapedLines = _escape(text).split('\n');
    final equationMarker = RegExp(r'\{\{EQ:([a-zA-Z0-9_]+)\}\}');
    final buffer = StringBuffer();
    for (var i = 0; i < escapedLines.length; i++) {
      final line = escapedLines[i];
      var cursor = 0;
      for (final marker in equationMarker.allMatches(line)) {
        if (marker.start > cursor) {
          final plainChunk = line.substring(cursor, marker.start);
          buffer.write('<w:r>');
          if (bold || rtl) {
            final runProperties = StringBuffer();
            if (bold) {
              runProperties.write('<w:b/>');
            }
            if (rtl) {
              runProperties.write('<w:rtl/>');
            }
            buffer.write('<w:rPr>$runProperties</w:rPr>');
          }
          buffer.write('<w:t xml:space="preserve">${plainChunk.isEmpty ? ' ' : plainChunk}</w:t>');
          buffer.write('</w:r>');
        }
        final token = marker.group(1) ?? '';
        final equationText = equationTextByToken[token];
        if (equationText != null && equationText.trim().isNotEmpty) {
          buffer.write(_inlineWordEquationXml(equationText));
        } else {
          buffer.write('<w:r><w:t xml:space="preserve">${line.substring(marker.start, marker.end)}</w:t></w:r>');
        }
        cursor = marker.end;
      }
      final tail = line.substring(cursor);
      buffer.write('<w:r>');
      if (bold || rtl) {
        final runProperties = StringBuffer();
        if (bold) {
          runProperties.write('<w:b/>');
        }
        if (rtl) {
          runProperties.write('<w:rtl/>');
        }
        buffer.write('<w:rPr>$runProperties</w:rPr>');
      }
      buffer.write('<w:t xml:space="preserve">${tail.isEmpty ? ' ' : tail}</w:t>');
      buffer.write('</w:r>');
      if (i < escapedLines.length - 1) {
        buffer.write('<w:r><w:br/></w:r>');
      }
    }
    return buffer.toString();
  }

  String _inlineWordEquationXml(String value) {
    final normalized = _stripInvalidXmlChars(value).trim();
    if (normalized.isEmpty) {
      return '<m:oMath><m:r><m:t xml:space="preserve"> </m:t></m:r></m:oMath>';
    }
    final content = _LatexToOmmlConverter(
      normalized,
      escape: _escape,
    ).convert();
    return '<m:oMath>$content</m:oMath>';
  }

  String _escape(String value) {
    return _stripInvalidXmlChars(value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _stripInvalidXmlChars(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final isAllowed =
          rune == 0x9 ||
          rune == 0xA ||
          rune == 0xD ||
          (rune >= 0x20 && rune <= 0xD7FF) ||
          (rune >= 0xE000 && rune <= 0xFFFD) ||
          (rune >= 0x10000 && rune <= 0x10FFFF);
      if (isAllowed) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  Future<Map<int, _EmbeddedImageAsset>> _prepareImageAssets(
    List<GeneratedQuestion> questions,
  ) async {
    final assetsByQuestion = <int, _EmbeddedImageAsset>{};
    var imageIndex = 1;
    for (var i = 0; i < questions.length; i++) {
      final imageRef = questions[i].imageRef.trim();
      if (imageRef.isEmpty) {
        continue;
      }

      final loadedImage = await _loadImageForExport(imageRef);
      if (loadedImage == null) {
        continue;
      }

      final relationshipId = 'rIdImage$imageIndex';
      final targetPath = 'media/image$imageIndex${loadedImage.extension}';
      assetsByQuestion[i] = _EmbeddedImageAsset(
        relationshipId: relationshipId,
        targetPath: targetPath,
        extension: loadedImage.extension,
        bytes: loadedImage.bytes,
      );
      imageIndex++;
    }
    return assetsByQuestion;
  }

  Future<_LoadedImageData?> _loadImageForExport(String imageRef) async {
    try {
      final dataImage = _parseDataImageUri(imageRef);
      if (dataImage != null && dataImage.bytes.isNotEmpty) {
        final extension = _normalizeImageExtension(
          dataImage.extension,
          bytes: dataImage.bytes,
        );
        if (!_isSupportedImageExtension(extension)) {
          return null;
        }
        return _LoadedImageData(bytes: dataImage.bytes, extension: extension);
      }

      final uri = Uri.tryParse(imageRef);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final client = HttpClient();
        try {
          final request = await client.getUrl(uri);
          final response = await request.close();
          if (response.statusCode < 200 || response.statusCode >= 300) {
            return null;
          }
          final bytes = await consolidateHttpClientResponseBytes(response);
          if (bytes.isEmpty) {
            return null;
          }
          final extension = _normalizeImageExtension(
            _extractImageExtension(uri.path),
            bytes: bytes,
          );
          if (!_isSupportedImageExtension(extension)) {
            return null;
          }
          return _LoadedImageData(bytes: bytes, extension: extension);
        } finally {
          client.close(force: true);
        }
      }

      final file = File(imageRef);
      if (!await file.exists()) {
        return null;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return null;
      }
      final extension = _normalizeImageExtension(
        _extractImageExtension(imageRef),
        bytes: bytes,
      );
      if (!_isSupportedImageExtension(extension)) {
        return null;
      }
      return _LoadedImageData(bytes: bytes, extension: extension);
    } catch (_) {
      return null;
    }
  }

  _ParsedDataImage? _parseDataImageUri(String value) {
    if (!value.startsWith('data:image/')) {
      return null;
    }
    final slash = value.indexOf('/');
    final semicolon = value.indexOf(';', slash + 1);
    final comma = value.indexOf(',', semicolon + 1);
    if (slash < 0 || semicolon <= slash || comma <= semicolon) {
      return null;
    }
    final meta = value.substring(semicolon + 1, comma).toLowerCase();
    if (!meta.contains('base64')) {
      return null;
    }
    final subtype = value.substring(slash + 1, semicolon).toLowerCase();
    final extension = switch (subtype) {
      'png' => '.png',
      'gif' => '.gif',
      'bmp' => '.bmp',
      'jpeg' || 'jpg' => '.jpg',
      _ => '.jpg',
    };
    try {
      final bytes = Uint8List.fromList(base64Decode(value.substring(comma + 1)));
      return _ParsedDataImage(bytes: bytes, extension: extension);
    } catch (_) {
      return null;
    }
  }

  String _normalizeImageExtension(
    String extension, {
    Uint8List? bytes,
  }) {
    final normalized = extension.startsWith('.') ? extension.toLowerCase() : '.${extension.toLowerCase()}';
    if (_isSupportedImageExtension(normalized)) {
      return normalized;
    }
    if (bytes == null) {
      return '.jpg';
    }
    return _detectImageExtension(bytes) ?? '.jpg';
  }

  String _extractImageExtension(String path) {
    final slashIndex = path.lastIndexOf('/');
    final fileName = slashIndex >= 0 ? path.substring(slashIndex + 1) : path;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }
    return fileName.substring(dotIndex).toLowerCase();
  }

  /// Detects common raster image formats from magic bytes.
  ///
  /// Supported signatures:
  /// - PNG (`0x89 0x50 0x4E 0x47` / `137 80 78 71`)
  /// - JPEG (`0xFF 0xD8 0xFF` / `255 216 255`)
  /// - GIF (`0x47 0x49 0x46 0x38` / `71 73 70 56`)
  /// - BMP (`0x42 0x4D` / `66 77`)
  ///
  /// Returns a normalized extension (e.g. `.png`) or `null` when unknown.
  String? _detectImageExtension(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return '.png';
    }
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return '.jpg';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return '.gif';
    }
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return '.bmp';
    }
    return null;
  }

  bool _isSupportedImageExtension(String extension) {
    return extension == '.png' ||
        extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.gif' ||
        extension == '.bmp' ||
        extension == '.svg';
  }

  String _buildContentTypes(List<_EmbeddedImageAsset> imageAssets) {
    final extensionDefaults = <String, String>{};
    for (final asset in imageAssets) {
      extensionDefaults[asset.extension.replaceFirst('.', '')] = _imageContentType(asset.extension);
    }
    final imageDefaults = extensionDefaults.entries
        .map((entry) => '  <Default Extension="${entry.key}" ContentType="${entry.value}"/>')
        .join('\n');
    final imageDefaultsSection = imageDefaults.isEmpty ? '' : '\n$imageDefaults';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>$imageDefaultsSection
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';
  }

  String _buildDocRels(List<_EmbeddedImageAsset> imageAssets) {
    final imageRelationships = imageAssets
        .map(
          (asset) =>
              '  <Relationship Id="${asset.relationshipId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="${asset.targetPath}"/>',
        )
        .join('\n');
    final imageSection = imageRelationships.isEmpty ? '' : '\n$imageRelationships';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>$imageSection
</Relationships>''';
  }

  String _imageContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.svg':
        return 'image/svg+xml';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _composeForExport({
    required String text,
    required String math,
  }) {
    final normalizedText = _normalizeTextForExport(text);
    final normalizedMath = FriendlyMathFormatter.format(math);
    if (normalizedMath.isEmpty) {
      return normalizedText;
    }
    if (normalizedText.isEmpty) {
      return normalizedMath;
    }
    return '$normalizedText  ($normalizedMath)';
  }

  String _composeRawForWordMath({
    required String text,
    required String math,
  }) {
    final normalizedText = text.trim();
    final normalizedMath = math.trim();
    if (normalizedMath.isEmpty) {
      return normalizedText;
    }
    final inlineMath = '\$\$$normalizedMath\$\$';
    if (normalizedText.isEmpty) {
      return inlineMath;
    }
    return '$normalizedText  ($inlineMath)';
  }

  String _normalizeTextForExport(String text) {
    return FriendlyMathFormatter.format(text);
  }

  bool _containsArabic(String value) {
    final arabicRange = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRange.hasMatch(value);
  }

  bool _isArabicLanguageCode(String? languageCode) {
    return (languageCode ?? '').trim().toLowerCase().startsWith('ar');
  }

  List<String> _maybeFlipCellsForRtl(List<String> cells, bool rtl) {
    return rtl ? cells.reversed.toList(growable: false) : cells;
  }

  List<String> _resolveOptionLabels({
    required String? optionLabelStyle,
    required bool exportInArabic,
  }) {
    final normalized = (optionLabelStyle ?? '').trim().toLowerCase();
    final useArabic = normalized == 'arabic' || (normalized.isEmpty && exportInArabic);
    return useArabic ? const ['أ', 'ب', 'ج', 'د'] : const ['A', 'B', 'C', 'D'];
  }
}

const _rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
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

class _EmbeddedImageAsset {
  _EmbeddedImageAsset({
    required this.relationshipId,
    required this.targetPath,
    required this.extension,
    required this.bytes,
  });

  final String relationshipId;
  final String targetPath;
  final String extension;
  final Uint8List bytes;
}

class _LoadedImageData {
  _LoadedImageData({
    required this.bytes,
    required this.extension,
  });

  final Uint8List bytes;
  final String extension;
}

class _ParsedDataImage {
  _ParsedDataImage({
    required this.bytes,
    required this.extension,
  });

  final Uint8List bytes;
  final String extension;
}

class _EquationAssetRegistry {
  _EquationAssetRegistry();
  static final RegExp _equationPattern = RegExp(r'\$\$(.+?)\$\$', dotAll: true);

  int _nextTokenIndex = 1;
  final Map<String, String> textByToken = <String, String>{};

  String encodeText(
    String value, {
    required String keyPrefix,
  }) {
    if (!_equationPattern.hasMatch(value)) {
      return value;
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in _equationPattern.allMatches(value)) {
      if (match.start > cursor) {
        buffer.write(value.substring(cursor, match.start));
      }
      final rawEquation = (match.group(1) ?? '').trim();
      if (rawEquation.isEmpty) {
        cursor = match.end;
        continue;
      }
      final token = '${keyPrefix}_eq_$_nextTokenIndex';
      textByToken[token] = rawEquation;
      buffer.write('{{EQ:$token}}');
      _nextTokenIndex++;
      cursor = match.end;
    }
    if (cursor < value.length) {
      buffer.write(value.substring(cursor));
    }
    return buffer.toString();
  }

}

class _LatexToOmmlConverter {
  _LatexToOmmlConverter(this._input, {required this.escape});

  final String _input;
  final String Function(String value) escape;
  int _index = 0;

  static const Map<String, String> _symbolMap = {
    'pi': 'π',
    'alpha': 'α',
    'beta': 'β',
    'gamma': 'γ',
    'delta': 'δ',
    'theta': 'θ',
    'lambda': 'λ',
    'mu': 'μ',
    'sigma': 'σ',
    'phi': 'φ',
    'omega': 'ω',
    'times': '×',
    'cdot': '·',
    'leq': '≤',
    'geq': '≥',
    'neq': '≠',
    'pm': '±',
    'to': '→',
    'infty': '∞',
  };

  String convert() {
    final nodes = _parseExpression();
    final xml = nodes.map(_toOmml).join();
    if (xml.isEmpty) {
      return '<m:r><m:t>${escape(_input)}</m:t></m:r>';
    }
    return xml;
  }

  List<_MathNode> _parseExpression({Set<String> stopChars = const {}}) {
    final nodes = <_MathNode>[];
    while (_index < _input.length) {
      final c = _input[_index];
      if (c == '}') {
        break;
      }
      if (stopChars.contains(c)) {
        break;
      }
      if (_match(r'\end{matrix}')) {
        break;
      }
      if (_isWhitespace(c)) {
        _index++;
        continue;
      }

      final atom = _parseAtom();
      if (atom == null) {
        _index++;
        continue;
      }
      nodes.add(_parseScripts(atom));
    }
    return nodes;
  }

  _MathNode? _parseAtom() {
    if (_index >= _input.length) {
      return null;
    }
    final c = _input[_index];
    if (c == '{') {
      _index++;
      final children = _parseExpression();
      if (_index < _input.length && _input[_index] == '}') {
        _index++;
      }
      return _GroupNode(children);
    }
    if (c == '\\') {
      return _parseCommand();
    }
    return _TextNode(_readPlainText());
  }

  _MathNode _parseScripts(_MathNode base) {
    _MathNode? sub;
    _MathNode? sup;
    while (_index < _input.length) {
      final c = _input[_index];
      if (c != '^' && c != '_') {
        break;
      }
      _index++;
      final arg = _parseScriptArgument();
      if (c == '^') {
        sup = arg;
      } else {
        sub = arg;
      }
    }
    if (sub == null && sup == null) {
      return base;
    }
    return _ScriptNode(base: base, sub: sub, sup: sup);
  }

  _MathNode _parseScriptArgument() {
    _skipWhitespace();
    if (_index >= _input.length) {
      return const _TextNode('');
    }
    final atom = _parseAtom();
    if (atom == null) {
      return const _TextNode('');
    }
    return _parseScripts(atom);
  }

  _MathNode _parseCommand() {
    _index++;
    if (_index >= _input.length) {
      return const _TextNode('\\');
    }
    final start = _index;
    while (_index < _input.length && _isAlpha(_input[_index])) {
      _index++;
    }
    if (start == _index) {
      final c = _input[_index++];
      if (c == '\\') {
        return const _TextNode('\\');
      }
      return _TextNode(c);
    }
    final command = _input.substring(start, _index);
    switch (command) {
      case 'frac':
        return _parseFraction();
      case 'sqrt':
        return _parseRoot();
      case 'sum':
        return _parseNary('∑');
      case 'int':
        return _parseNary('∫');
      case 'begin':
        return _parseBeginEnvironment();
      case 'left':
      case 'right':
        return _parseAtom() ?? const _TextNode('');
      default:
        return _TextNode(_symbolMap[command] ?? '\\$command');
    }
  }

  _MathNode _parseFraction() {
    final numerator = _parseRequiredGroupOrAtom();
    final denominator = _parseRequiredGroupOrAtom();
    return _FractionNode(numerator: numerator, denominator: denominator);
  }

  _MathNode _parseRoot() {
    _skipWhitespace();
    _MathNode? degree;
    if (_index < _input.length && _input[_index] == '[') {
      _index++;
      final content = _parseExpression(stopChars: {']'});
      if (_index < _input.length && _input[_index] == ']') {
        _index++;
      }
      degree = _GroupNode(content);
    }
    final radicand = _parseRequiredGroupOrAtom();
    return _RootNode(radicand: radicand, degree: degree);
  }

  _MathNode _parseNary(String chr) {
    _skipWhitespace();
    _MathNode? sub;
    _MathNode? sup;
    while (_index < _input.length) {
      final c = _input[_index];
      if (c != '_' && c != '^') {
        break;
      }
      _index++;
      final arg = _parseScriptArgument();
      if (c == '_') {
        sub = arg;
      } else {
        sup = arg;
      }
      _skipWhitespace();
    }
    _skipWhitespace();
    final body = _index < _input.length ? _parseRequiredGroupOrAtom() : const _TextNode('');
    return _NaryNode(chr: chr, sub: sub, sup: sup, body: body);
  }

  _MathNode _parseBeginEnvironment() {
    _skipWhitespace();
    if (_index >= _input.length || _input[_index] != '{') {
      return const _TextNode(r'\begin');
    }
    final environmentName = _parseRawGroupText();
    if (environmentName != 'matrix') {
      return _TextNode('\\begin{$environmentName}');
    }

    final endToken = r'\end{matrix}';
    final endIndex = _input.indexOf(endToken, _index);
    if (endIndex < 0) {
      return const _TextNode(r'\begin{matrix}');
    }

    final matrixBody = _input.substring(_index, endIndex);
    _index = endIndex + endToken.length;

    final rows = matrixBody
        .split(RegExp(r'\\\\'))
        .map(
          (row) => row
              .split('&')
              .map((cell) => _GroupNode(_LatexToOmmlConverter(cell.trim(), escape: escape)._parseExpression()))
              .toList(growable: false),
        )
        .toList(growable: false);
    return _MatrixNode(rows: rows);
  }

  _MathNode _parseRequiredGroupOrAtom() {
    _skipWhitespace();
    if (_index >= _input.length) {
      return const _TextNode('');
    }
    final atom = _parseAtom();
    if (atom == null) {
      return const _TextNode('');
    }
    return _parseScripts(atom);
  }

  String _parseRawGroupText() {
    if (_index >= _input.length || _input[_index] != '{') {
      return '';
    }
    _index++;
    final start = _index;
    while (_index < _input.length && _input[_index] != '}') {
      _index++;
    }
    final value = _input.substring(start, _index);
    if (_index < _input.length && _input[_index] == '}') {
      _index++;
    }
    return value.trim();
  }

  String _readPlainText() {
    final start = _index;
    while (_index < _input.length) {
      final c = _input[_index];
      if (c == '\\' || c == '{' || c == '}' || c == '^' || c == '_' || _isWhitespace(c)) {
        break;
      }
      _index++;
    }
    return _input.substring(start, _index);
  }

  bool _isWhitespace(String c) => c.trim().isEmpty;

  bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _match(String value) => _input.startsWith(value, _index);

  void _skipWhitespace() {
    while (_index < _input.length && _isWhitespace(_input[_index])) {
      _index++;
    }
  }

  String _toOmml(_MathNode node) {
    if (node is _TextNode) {
      final text = node.value;
      if (text.isEmpty) {
        return '';
      }
      return '<m:r><m:t>${escape(text)}</m:t></m:r>';
    }
    if (node is _GroupNode) {
      return node.children.map(_toOmml).join();
    }
    if (node is _FractionNode) {
      return '<m:f><m:num>${_asArg(node.numerator)}</m:num><m:den>${_asArg(node.denominator)}</m:den></m:f>';
    }
    if (node is _RootNode) {
      if (node.degree == null) {
        return '<m:rad><m:radPr><m:degHide m:val="1"/></m:radPr><m:e>${_asArg(node.radicand)}</m:e></m:rad>';
      }
      return '<m:rad><m:deg>${_asArg(node.degree!)}</m:deg><m:e>${_asArg(node.radicand)}</m:e></m:rad>';
    }
    if (node is _ScriptNode) {
      final base = _asArg(node.base);
      final sub = node.sub == null ? '' : _asArg(node.sub!);
      final sup = node.sup == null ? '' : _asArg(node.sup!);
      if (node.sub != null && node.sup != null) {
        return '<m:sSubSup><m:e>$base</m:e><m:sub>$sub</m:sub><m:sup>$sup</m:sup></m:sSubSup>';
      }
      if (node.sub != null) {
        return '<m:sSub><m:e>$base</m:e><m:sub>$sub</m:sub></m:sSub>';
      }
      return '<m:sSup><m:e>$base</m:e><m:sup>$sup</m:sup></m:sSup>';
    }
    if (node is _NaryNode) {
      final sub = node.sub == null ? '<m:sub><m:r><m:t></m:t></m:r></m:sub>' : '<m:sub>${_asArg(node.sub!)}</m:sub>';
      final sup = node.sup == null ? '<m:sup><m:r><m:t></m:t></m:r></m:sup>' : '<m:sup>${_asArg(node.sup!)}</m:sup>';
      return '<m:nary><m:naryPr><m:chr m:val="${escape(node.chr)}"/></m:naryPr>$sub$sup<m:e>${_asArg(node.body)}</m:e></m:nary>';
    }
    if (node is _MatrixNode) {
      final rowsXml = node.rows
          .map(
            (row) =>
                '<m:mr>${row.map((cell) => '<m:e>${_asArg(cell)}</m:e>').join()}</m:mr>',
          )
          .join();
      return '<m:m><m:mPr/>$rowsXml</m:m>';
    }
    return '<m:r><m:t>${escape(_input)}</m:t></m:r>';
  }

  String _asArg(_MathNode node) {
    final xml = _toOmml(node);
    if (xml.isEmpty) {
      return '<m:r><m:t xml:space="preserve"> </m:t></m:r>';
    }
    return xml;
  }
}

sealed class _MathNode {
  const _MathNode();
}

class _TextNode extends _MathNode {
  const _TextNode(this.value);
  final String value;
}

class _GroupNode extends _MathNode {
  const _GroupNode(this.children);
  final List<_MathNode> children;
}

class _FractionNode extends _MathNode {
  const _FractionNode({
    required this.numerator,
    required this.denominator,
  });
  final _MathNode numerator;
  final _MathNode denominator;
}

class _RootNode extends _MathNode {
  const _RootNode({
    required this.radicand,
    this.degree,
  });
  final _MathNode radicand;
  final _MathNode? degree;
}

class _ScriptNode extends _MathNode {
  const _ScriptNode({
    required this.base,
    this.sub,
    this.sup,
  });
  final _MathNode base;
  final _MathNode? sub;
  final _MathNode? sup;
}

class _NaryNode extends _MathNode {
  const _NaryNode({
    required this.chr,
    this.sub,
    this.sup,
    required this.body,
  });
  final String chr;
  final _MathNode? sub;
  final _MathNode? sup;
  final _MathNode body;
}

class _MatrixNode extends _MathNode {
  const _MatrixNode({
    required this.rows,
  });
  final List<List<_MathNode>> rows;
}
