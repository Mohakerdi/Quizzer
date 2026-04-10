import 'package:adv_basics/models/question_option.dart';
import 'package:adv_basics/utils/friendly_math_formatter.dart';
import 'package:uuid/uuid.dart';

class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionId,
    this.math = '',
    this.imageRef = '',
    this.topic = '',
    this.difficulty = '',
    this.gradeLevel = '',
    this.unitOfStudy = '',
    this.curriculum = '',
  });

  final String id;
  final String text;
  final String math;
  final String imageRef;
  final String topic;
  final String difficulty;
  final String gradeLevel;
  final String unitOfStudy;
  final String curriculum;
  final List<QuestionOption> options;
  final String correctOptionId;

  factory QuizQuestion.create() {
    final first = QuestionOption.create();
    final second = QuestionOption.create();

    return QuizQuestion(
      id: const Uuid().v4(),
      text: '',
      options: [first, second],
      correctOptionId: first.id,
    );
  }

  QuizQuestion copyWith({
    String? id,
    String? text,
    String? math,
    String? imageRef,
    String? topic,
    String? difficulty,
    String? gradeLevel,
    String? unitOfStudy,
    String? curriculum,
    List<QuestionOption>? options,
    String? correctOptionId,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      math: math ?? this.math,
      imageRef: imageRef ?? this.imageRef,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      unitOfStudy: unitOfStudy ?? this.unitOfStudy,
      curriculum: curriculum ?? this.curriculum,
      options: options ?? this.options,
      correctOptionId: correctOptionId ?? this.correctOptionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'math': math,
      'imageRef': imageRef,
      'topic': topic,
      'difficulty': difficulty,
      'gradeLevel': gradeLevel,
      'unitOfStudy': unitOfStudy,
      'curriculum': curriculum,
      'options': options.map((o) => o.toJson()).toList(),
      'correctOptionId': correctOptionId,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>? ?? [])
        .map((option) => QuestionOption.fromJson(option as Map<String, dynamic>))
        .toList();

    final fallbackCorrectId = options.isNotEmpty ? options.first.id : '';

    return QuizQuestion(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      math: json['math'] as String? ?? '',
      imageRef: json['imageRef'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      gradeLevel: json['gradeLevel'] as String? ?? '',
      unitOfStudy: json['unitOfStudy'] as String? ?? '',
      curriculum: json['curriculum'] as String? ?? '',
      options: options,
      correctOptionId: json['correctOptionId'] as String? ?? fallbackCorrectId,
    );
  }

  String get composedPrompt {
    final normalizedText = FriendlyMathFormatter.format(text);
    final normalizedMath = FriendlyMathFormatter.format(math);
    if (normalizedMath.isEmpty) {
      return normalizedText;
    }
    if (normalizedText.isEmpty) {
      return normalizedMath;
    }
    return '$normalizedText  ($normalizedMath)';
  }
}
