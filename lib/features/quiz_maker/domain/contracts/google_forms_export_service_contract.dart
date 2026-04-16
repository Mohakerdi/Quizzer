import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';

class GoogleFormsExportOutput {
  const GoogleFormsExportOutput({
    required this.scriptPath,
    required this.jsonPath,
  });

  final String scriptPath;
  final String jsonPath;
}

abstract class GoogleFormsExportServiceContract {
  Future<GoogleFormsExportOutput> exportVariant({
    required QuizModel quiz,
    required GeneratedVariant variant,
  });
}
