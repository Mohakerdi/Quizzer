import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/features/quiz_maker/domain/contracts/google_forms_export_service_contract.dart';
import 'package:adv_basics/features/quiz_maker/domain/contracts/quiz_repository_contract.dart';
import 'package:adv_basics/features/quiz_maker/domain/contracts/variant_export_service_contract.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/question_clone_service.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/variant_generator.dart';
import 'package:uuid/uuid.dart';

class CreateQuizUseCase {
  const CreateQuizUseCase(this._repository);

  final QuizRepositoryContract _repository;

  Future<QuizModel> call(String title) async {
    return _repository.upsertQuiz(QuizModel.empty(title.trim()));
  }
}

class CreateQuizFromQuestionBankUseCase {
  const CreateQuizFromQuestionBankUseCase(this._repository);

  final QuizRepositoryContract _repository;

  Future<QuizModel> call({
    required String title,
    required List<QuizQuestion> questions,
  }) async {
    final now = DateTime.now();
    final quiz = QuizModel(
      id: const Uuid().v4(),
      title: title.trim(),
      version: 1,
      questions: questions.map(QuestionCloneService.cloneForNewQuiz).toList(),
      createdAt: now,
      updatedAt: now,
    );
    return _repository.upsertQuiz(quiz);
  }
}

class RenameQuizUseCase {
  const RenameQuizUseCase(this._repository);

  final QuizRepositoryContract _repository;

  Future<QuizModel> call({
    required QuizModel quiz,
    required String title,
  }) async {
    return _repository.upsertQuiz(
      quiz.copyWith(title: title.trim(), updatedAt: DateTime.now()),
    );
  }
}

class DuplicateQuizUseCase {
  const DuplicateQuizUseCase(this._repository);

  final QuizRepositoryContract _repository;

  Future<QuizModel> call(QuizModel quiz) async {
    return _repository.upsertQuiz(quiz.duplicate());
  }
}

class GenerateVariantsUseCase {
  const GenerateVariantsUseCase(this._variantGenerator);

  final VariantGenerator _variantGenerator;

  List<GeneratedVariant> call({
    required QuizModel quiz,
    required int count,
  }) {
    return _variantGenerator.generate(quiz: quiz, count: count);
  }
}

class ExportVariantUseCase {
  const ExportVariantUseCase(this._exportService);

  final VariantExportServiceContract _exportService;

  Future<List<String>> call({
    required QuizModel quiz,
    required GeneratedVariant variant,
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
  }) async {
    final quizDocPath = await _exportService.exportQuizPaper(
      quiz: quiz,
      variant: variant,
      teacherName: teacherName,
      schoolName: schoolName,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
    );
    final solutionDocPath = await _exportService.exportSolutions(
      quiz: quiz,
      variant: variant,
      exportLanguageCode: exportLanguageCode,
      optionLabelStyle: optionLabelStyle,
    );
    return [quizDocPath, solutionDocPath];
  }
}

class ExportAllVariantsUseCase {
  const ExportAllVariantsUseCase(this._exportVariantUseCase);

  final ExportVariantUseCase _exportVariantUseCase;

  Future<List<String>> call({
    required QuizModel quiz,
    required List<GeneratedVariant> variants,
    String? teacherName,
    String? schoolName,
    String? exportLanguageCode,
    String? optionLabelStyle,
  }) async {
    final exported = <String>[];
    for (final variant in variants) {
      exported.addAll(
        await _exportVariantUseCase(
          quiz: quiz,
          variant: variant,
          teacherName: teacherName,
          schoolName: schoolName,
          exportLanguageCode: exportLanguageCode,
          optionLabelStyle: optionLabelStyle,
        ),
      );
    }
    return exported;
  }
}

class ExportVariantToGoogleFormsUseCase {
  const ExportVariantToGoogleFormsUseCase(this._googleFormsService);

  final GoogleFormsExportServiceContract _googleFormsService;

  Future<GoogleFormsExportOutput> call({
    required QuizModel quiz,
    required GeneratedVariant variant,
  }) {
    return _googleFormsService.exportVariant(quiz: quiz, variant: variant);
  }
}
