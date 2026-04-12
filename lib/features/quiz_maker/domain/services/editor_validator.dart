import 'package:adv_basics/data/models/quiz_model.dart';

class EditorValidator {
  const EditorValidator();

  List<String> validate(QuizModel quiz) {
    final errors = <String>[];

    if (quiz.title.trim().isEmpty) {
      errors.add('Quiz title is required.');
    }

    if (quiz.questions.isEmpty) {
      errors.add('At least one question is required.');
      return errors;
    }

    for (var i = 0; i < quiz.questions.length; i++) {
      final question = quiz.questions[i];
      final label = 'Q${i + 1}';

      if (question.text.trim().isEmpty && question.math.trim().isEmpty) {
        errors.add('$label: question text or math expression is required.');
      }

      if (question.options.length < 2) {
        errors.add('$label: at least 2 options are required.');
      }

      final hasCorrect = question.options.any((o) => o.id == question.correctOptionId);
      if (!hasCorrect) {
        errors.add('$label: select one correct answer.');
      }

      for (var j = 0; j < question.options.length; j++) {
        final option = question.options[j];
        if (option.text.trim().isEmpty && option.math.trim().isEmpty) {
          errors.add('$label: option ${j + 1} is empty.');
        }
      }
    }

    return errors;
  }
}
