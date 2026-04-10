import 'dart:math';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/question_option.dart';
import 'package:adv_basics/models/quiz_model.dart';

class VariantGenerator {
  const VariantGenerator();

  List<GeneratedVariant> generate({
    required QuizModel quiz,
    required int count,
  }) {
    final createdAt = DateTime.now();

    return List.generate(count, (index) {
      final seed = createdAt.microsecondsSinceEpoch + index;
      final random = Random(seed);

      final shuffledQuestions = [...quiz.questions]..shuffle(random);
      final generatedQuestions = <GeneratedQuestion>[];

      for (final question in shuffledQuestions) {
        final optionRandom = Random(seed ^ question.id.hashCode);
        final shuffledOptions = [...question.options]..shuffle(optionRandom);

        generatedQuestions.add(
          GeneratedQuestion(
            questionId: question.id,
            text: question.text,
            math: question.math,
            imageRef: question.imageRef,
            options: shuffledOptions
                .map(
                  (o) => QuestionOption(
                    id: o.id,
                    text: o.text,
                    math: o.math,
                  ),
                )
                .toList(),
            correctOptionId: question.correctOptionId,
          ),
        );
      }

      return GeneratedVariant(
        id: 'V${index + 1}',
        quizId: quiz.id,
        seed: seed,
        generatedAt: createdAt,
        questions: generatedQuestions,
      );
    });
  }
}
