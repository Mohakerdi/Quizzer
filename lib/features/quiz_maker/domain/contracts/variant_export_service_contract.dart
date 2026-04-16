import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';

abstract class VariantExportServiceContract {
  Future<String> exportQuizPaper({
    required QuizModel quiz,
    required GeneratedVariant variant,
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
  });

  Future<String> exportSolutions({
    required QuizModel quiz,
    required GeneratedVariant variant,
    String? exportLanguageCode,
    String? optionLabelStyle,
  });
}
