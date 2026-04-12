import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:uuid/uuid.dart';

class QuizModel {
  QuizModel({
    required this.id,
    required this.title,
    required this.version,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final int version;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory QuizModel.empty(String title) {
    final now = DateTime.now();
    return QuizModel(
      id: const Uuid().v4(),
      title: title,
      version: 1,
      questions: [QuizQuestion.create()],
      createdAt: now,
      updatedAt: now,
    );
  }

  QuizModel copyWith({
    String? id,
    String? title,
    int? version,
    List<QuizQuestion>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      version: version ?? this.version,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  QuizModel duplicate() {
    final now = DateTime.now();
    return copyWith(
      id: const Uuid().v4(),
      title: '$title (copy)',
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'version': version,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Quiz',
      version: json['version'] as int? ?? 1,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((question) => QuizQuestion.fromJson(question as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
