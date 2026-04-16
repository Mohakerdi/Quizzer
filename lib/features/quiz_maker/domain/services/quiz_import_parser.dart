import 'dart:convert';

import 'package:adv_basics/data/models/question_option.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:uuid/uuid.dart';

class QuizImportParser {
  const QuizImportParser();

  /// Parses one quiz JSON payload and preserves `math` text as decoded from JSON.
  ///
  /// For LaTeX content, callers should provide valid JSON escaping, e.g. `\\frac`
  /// inside JSON to represent a single backslash in the final parsed string.
  QuizModel parseSingleQuiz(String rawJson) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (_) {
      throw const FormatException('Invalid JSON: expected a valid JSON string.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON structure: expected a JSON object (curly braces).');
    }

    final now = DateTime.now();
    final quizMap = _extractQuizMap(decoded);
    final title = (quizMap['title'] as String?)?.trim();
    final normalizedTitle = title == null || title.isEmpty ? 'Imported Quiz' : title;

    final questions = _parseQuestions(quizMap['questions']);
    if (questions.isEmpty) {
      throw const FormatException('Quiz must contain at least one question in the questions array.');
    }

    final parsedCreatedAt = _parseDateTime(quizMap['createdAt']);
    final parsedUpdatedAt = _parseDateTime(quizMap['updatedAt']);

    return QuizModel(
      id: const Uuid().v4(),
      title: normalizedTitle,
      version: 1,
      questions: questions,
      createdAt: parsedCreatedAt ?? now,
      updatedAt: parsedUpdatedAt ?? now,
    );
  }

  Map<String, dynamic> _extractQuizMap(Map<String, dynamic> decoded) {
    final nestedQuiz = decoded['quiz'];
    if (nestedQuiz is Map<String, dynamic>) {
      return nestedQuiz;
    }
    return decoded;
  }

  List<QuizQuestion> _parseQuestions(Object? rawQuestions) {
    final questionsList = rawQuestions is List ? rawQuestions : const [];
    final parsedQuestions = <QuizQuestion>[];

    for (final questionRaw in questionsList) {
      if (questionRaw is! Map<String, dynamic>) {
        continue;
      }
      parsedQuestions.add(_parseQuestion(questionRaw));
    }

    return parsedQuestions;
  }

  DateTime? _parseDateTime(Object? rawValue) {
    final text = rawValue as String?;
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  QuizQuestion _parseQuestion(Map<String, dynamic> json) {
    final parsedOptions = _parseOptions(json['options']);
    final options = parsedOptions.options;
    final ensuredOptions = options.length >= 2
        ? options
        : [
            ...options,
            ...List.generate(
              2 - options.length,
              (_) => QuestionOption.create(),
            ),
          ];

    final providedCorrectId = json['correctOptionId'] as String?;

    final fallbackCorrectId = ensuredOptions.first.id;
    final correctId = ensuredOptions.any((o) => o.id == providedCorrectId)
        ? providedCorrectId!
        : (parsedOptions.correctOptionIdByFlag ?? fallbackCorrectId);

    return QuizQuestion(
      id: const Uuid().v4(),
      text: _normalizeImportedText((json['text'] as String?) ?? ''),
      math: (json['math'] as String?) ?? '',
      imageRef: (json['imageRef'] as String?) ?? '',
      topic: (json['topic'] as String?) ?? '',
      difficulty: (json['difficulty'] as String?) ?? '',
      gradeLevel: (json['gradeLevel'] as String?) ?? '',
      unitOfStudy: (json['unitOfStudy'] as String?) ?? '',
      curriculum: (json['curriculum'] as String?) ?? '',
      options: ensuredOptions,
      correctOptionId: correctId,
    );
  }

  _ParsedOptions _parseOptions(Object? rawOptions) {
    final optionsList = rawOptions is List ? rawOptions : const [];
    final parsed = <QuestionOption>[];
    String? correctOptionIdByFlag;
    for (final optionRaw in optionsList) {
      if (optionRaw is! Map<String, dynamic>) {
        continue;
      }
      final importedId = (optionRaw['id'] as String?)?.trim();
      final option = QuestionOption(
        id: importedId == null || importedId.isEmpty ? const Uuid().v4() : importedId,
        text: _normalizeImportedText((optionRaw['text'] as String?) ?? ''),
        math: (optionRaw['math'] as String?) ?? '',
      );
      if (correctOptionIdByFlag == null && optionRaw['isCorrect'] == true) {
        correctOptionIdByFlag = option.id;
      }
      parsed.add(option);
    }
    return _ParsedOptions(
      options: parsed,
      correctOptionIdByFlag: correctOptionIdByFlag,
    );
  }

  String _normalizeImportedText(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (_hasMathDelimiters(normalized)) {
      return normalized;
    }
    if (_looksLikeLatexMath(normalized)) {
      return '\$\$$normalized\$\$';
    }
    return normalized;
  }

  bool _hasMathDelimiters(String value) {
    return RegExp(r'\\?\$\$').hasMatch(value);
  }

  bool _looksLikeLatexMath(String value) {
    return RegExp(
      r'\\(frac|dfrac|tfrac|cfrac|sqrt|sum|int|pi|theta|times|div|leq|geq|neq|alpha|beta|gamma|delta|lambda|mu|sigma|omega|sin|cos|tan|cot|sec|csc|log|ln|lim|cdot|pm|mp|left|right|begin|end)\b',
    ).hasMatch(value);
  }
}

/// Parsed option list and the first option id marked with `isCorrect: true`.
class _ParsedOptions {
  const _ParsedOptions({
    required this.options,
    required this.correctOptionIdByFlag,
  });

  final List<QuestionOption> options;
  final String? correctOptionIdByFlag;
}
