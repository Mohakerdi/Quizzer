import 'package:adv_basics/models/question_option.dart';
import 'package:adv_basics/utils/friendly_math_formatter.dart';

class GeneratedVariant {
  GeneratedVariant({
    required this.id,
    required this.quizId,
    required this.seed,
    required this.questions,
    required this.generatedAt,
  });

  final String id;
  final String quizId;
  final int seed;
  final List<GeneratedQuestion> questions;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'seed': seed,
      'generatedAt': generatedAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  factory GeneratedVariant.fromJson(Map<String, dynamic> json) {
    return GeneratedVariant(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      seed: json['seed'] as int,
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((question) => GeneratedQuestion.fromJson(question as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GeneratedQuestion {
  GeneratedQuestion({
    required this.questionId,
    required this.text,
    required this.math,
    required this.imageRef,
    required this.options,
    required this.correctOptionId,
  });

  final String questionId;
  final String text;
  final String math;
  final String imageRef;
  final List<QuestionOption> options;
  final String correctOptionId;

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'text': text,
      'math': math,
      'imageRef': imageRef,
      'options': options.map((o) => o.toJson()).toList(),
      'correctOptionId': correctOptionId,
    };
  }

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestion(
      questionId: json['questionId'] as String,
      text: json['text'] as String? ?? '',
      math: json['math'] as String? ?? '',
      imageRef: json['imageRef'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((option) => QuestionOption.fromJson(option as Map<String, dynamic>))
          .toList(),
      correctOptionId: json['correctOptionId'] as String? ?? '',
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
