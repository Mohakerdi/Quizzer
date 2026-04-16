import 'package:adv_basics/data/datasources/quiz_local_data_source.dart';
import 'package:adv_basics/data/repositories/quiz_repository.dart';
import 'package:adv_basics/data/services/docx_export_service.dart';
import 'package:adv_basics/data/services/google_forms_export_service.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/variant_generator.dart';
import 'package:adv_basics/features/quiz_maker/domain/usecases/quiz_session_use_cases.dart';

class AppDependencies {
  AppDependencies._({
    required this.quizRepository,
    required this.createQuizUseCase,
    required this.createQuizFromQuestionBankUseCase,
    required this.renameQuizUseCase,
    required this.duplicateQuizUseCase,
    required this.generateVariantsUseCase,
    required this.exportVariantUseCase,
    required this.exportAllVariantsUseCase,
    required this.exportVariantToGoogleFormsUseCase,
  });

  final QuizRepository quizRepository;
  final CreateQuizUseCase createQuizUseCase;
  final CreateQuizFromQuestionBankUseCase createQuizFromQuestionBankUseCase;
  final RenameQuizUseCase renameQuizUseCase;
  final DuplicateQuizUseCase duplicateQuizUseCase;
  final GenerateVariantsUseCase generateVariantsUseCase;
  final ExportVariantUseCase exportVariantUseCase;
  final ExportAllVariantsUseCase exportAllVariantsUseCase;
  final ExportVariantToGoogleFormsUseCase exportVariantToGoogleFormsUseCase;

  factory AppDependencies.create() {
    final repository = QuizRepository(
      localDataSource: const SharedPreferencesQuizLocalDataSource(),
    );
    final variantGenerator = const VariantGenerator();
    final docxExportService = const DocxExportService();
    final googleFormsExportService = const GoogleFormsExportService();
    final exportVariantUseCase = ExportVariantUseCase(docxExportService);

    return AppDependencies._(
      quizRepository: repository,
      createQuizUseCase: CreateQuizUseCase(repository),
      createQuizFromQuestionBankUseCase: CreateQuizFromQuestionBankUseCase(repository),
      renameQuizUseCase: RenameQuizUseCase(repository),
      duplicateQuizUseCase: DuplicateQuizUseCase(repository),
      generateVariantsUseCase: GenerateVariantsUseCase(variantGenerator),
      exportVariantUseCase: exportVariantUseCase,
      exportAllVariantsUseCase: ExportAllVariantsUseCase(exportVariantUseCase),
      exportVariantToGoogleFormsUseCase: ExportVariantToGoogleFormsUseCase(googleFormsExportService),
    );
  }
}
