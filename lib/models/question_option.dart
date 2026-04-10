import 'package:uuid/uuid.dart';

class QuestionOption {
  QuestionOption({
    required this.id,
    required this.text,
    this.math = '',
  });

  final String id;
  final String text;
  final String math;

  factory QuestionOption.create() {
    return QuestionOption(
      id: const Uuid().v4(),
      text: '',
    );
  }

  QuestionOption copyWith({
    String? id,
    String? text,
    String? math,
  }) {
    return QuestionOption(
      id: id ?? this.id,
      text: text ?? this.text,
      math: math ?? this.math,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'math': math,
    };
  }

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      math: json['math'] as String? ?? '',
    );
  }

  String get composedText {
    if (math.trim().isEmpty) {
      return text.trim();
    }

    if (text.trim().isEmpty) {
      return r'$' + math.trim() + r'$';
    }

    return '${text.trim()}  (${r'$'}${math.trim()}${r'$'})';
  }
}
