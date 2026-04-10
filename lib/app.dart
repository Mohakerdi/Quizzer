import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:adv_basics/l10n/app_strings.dart';
import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/models/quiz_question.dart';
import 'package:adv_basics/screens/question_bank_screen.dart';
import 'package:adv_basics/screens/quiz_editor_screen.dart';
import 'package:adv_basics/screens/quiz_list_screen.dart';
import 'package:adv_basics/screens/variant_preview_screen.dart';
import 'package:adv_basics/services/docx_export_service.dart';
import 'package:adv_basics/services/google_forms_export_service.dart';
import 'package:adv_basics/services/quiz_repository.dart';
import 'package:adv_basics/services/variant_generator.dart';
import 'package:adv_basics/view_models/quiz_maker_cubit.dart';
import 'package:adv_basics/view_models/quiz_maker_state.dart';

class QuizMakerApp extends StatelessWidget {
  const QuizMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizMakerCubit(
        repository: QuizRepository(),
        variantGenerator: const VariantGenerator(),
        docxExportService: const DocxExportService(),
        googleFormsExportService: const GoogleFormsExportService(),
      )..loadData(),
      child: BlocBuilder<QuizMakerCubit, QuizMakerState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Quizzer Maker',
            locale: state.locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D3FD3)),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5D3FD3),
                brightness: Brightness.dark,
              ),
            ),
            themeMode: state.themeMode,
            home: const QuizMakerHome(),
          );
        },
      ),
    );
  }
}

class QuizMakerHome extends StatelessWidget {
  const QuizMakerHome({super.key});

  Future<String?> _promptText(
    BuildContext context,
    String title,
    String hint, {
    String initialText = '',
  }) async {
    final controller = TextEditingController(text: initialText);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(AppStrings.tr(context, 'ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _createQuiz(BuildContext context) async {
    final title = await _promptText(
      context,
      AppStrings.tr(context, 'createQuiz'),
      AppStrings.tr(context, 'quizTitle'),
    );
    if (title == null || title.trim().isEmpty || !context.mounted) {
      return;
    }
    await context.read<QuizMakerCubit>().createQuiz(title.trim());
  }

  Future<void> _renameQuiz(BuildContext context, QuizModel quiz) async {
    final title = await _promptText(
      context,
      AppStrings.tr(context, 'renameQuiz'),
      AppStrings.tr(context, 'quizTitle'),
      initialText: quiz.title,
    );
    if (title == null || title.trim().isEmpty || !context.mounted) {
      return;
    }

    await context.read<QuizMakerCubit>().renameQuiz(quiz: quiz, title: title.trim());
  }

  Future<void> _generateVariants(BuildContext context, QuizModel quiz) async {
    final countText = await _promptText(
      context,
      AppStrings.tr(context, 'generateVariants'),
      AppStrings.tr(context, 'howManyVersions'),
      initialText: '2',
    );

    if (countText == null || !context.mounted) {
      return;
    }

    final count = int.tryParse(countText);
    if (count == null || count < 1) {
      context.read<QuizMakerCubit>().clearMessage();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(AppStrings.tr(context, 'invalidVariantsCount'))));
      return;
    }

    await context.read<QuizMakerCubit>().generateVariants(quiz: quiz, count: count);
  }

  Future<void> _previewVariant(BuildContext context, GeneratedVariant variant) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VariantPreviewScreen(variant: variant),
      ),
    );
  }

  List<BankQuestionEntry> _collectQuestionBankEntries(List<QuizModel> quizzes) {
    return quizzes
        .expand(
          (quiz) => quiz.questions.map(
            (question) => BankQuestionEntry(
              quizId: quiz.id,
              quizTitle: quiz.title,
              question: question,
            ),
          ),
        )
        .toList();
  }

  Future<void> _createQuizFromBankSelection(
    BuildContext context,
    List<QuizQuestion> selectedQuestions,
  ) async {
    final title = await _promptText(
      context,
      AppStrings.tr(context, 'createQuizFromSelection'),
      AppStrings.tr(context, 'newQuizFromBankTitle'),
      initialText: 'Quick Quiz',
    );
    if (title == null || title.trim().isEmpty || !context.mounted) {
      return;
    }
    await context.read<QuizMakerCubit>().createQuizFromQuestionBank(
          title: title.trim(),
          questions: selectedQuestions,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizMakerCubit, QuizMakerState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null || message.isEmpty) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));

        context.read<QuizMakerCubit>().clearMessage();
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.tr(context, 'appTitle')),
            actions: [
              IconButton(
                icon: Icon(state.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                tooltip: state.themeMode == ThemeMode.dark
                    ? AppStrings.tr(context, 'themeLight')
                    : AppStrings.tr(context, 'themeDark'),
                onPressed: () => context.read<QuizMakerCubit>().toggleThemeMode(),
              ),
              PopupMenuButton<Locale>(
                icon: const Icon(Icons.language),
                onSelected: (locale) => context.read<QuizMakerCubit>().setLocale(locale),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: Locale('en'), child: Text('English')),
                  PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
                ],
              ),
            ],
          ),
          body: Row(
            children: [
              SizedBox(
                width: 340,
                child: QuizListScreen(
                  quizzes: state.quizzes,
                  selectedQuizId: state.selectedQuiz?.id,
                  onCreateQuiz: () => _createQuiz(context),
                  onSelectQuiz: (quiz) => context.read<QuizMakerCubit>().selectQuiz(quiz),
                  onRenameQuiz: (quiz) => _renameQuiz(context, quiz),
                  onDuplicateQuiz: (quiz) => context.read<QuizMakerCubit>().duplicateQuiz(quiz),
                  onDeleteQuiz: (quiz) => context.read<QuizMakerCubit>().deleteQuiz(quiz),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: AppStrings.tr(context, 'quizEditorTab')),
                          Tab(text: AppStrings.tr(context, 'questionBankTab')),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            state.selectedQuiz == null
                                ? Center(child: Text(AppStrings.tr(context, 'selectQuiz')))
                                : QuizEditorScreen(
                                    quiz: state.selectedQuiz!,
                                    generatedVariants: state.generatedVariants,
                                    onQuizChanged: (quiz) => context.read<QuizMakerCubit>().saveQuiz(quiz),
                                    onQuizAutoSave: (quiz) => context.read<QuizMakerCubit>().saveQuizSilently(quiz),
                                    onGenerateVariants: (quiz) => _generateVariants(context, quiz),
                                    onPreviewVariant: (variant) => _previewVariant(context, variant),
                                    onExportVariant: (variant, {teacherName, schoolName}) => context
                                        .read<QuizMakerCubit>()
                                        .exportVariant(
                                          variant,
                                          teacherName: teacherName,
                                          schoolName: schoolName,
                                        ),
                                    onExportGoogleForms: (variant) =>
                                        context.read<QuizMakerCubit>().exportVariantToGoogleForms(variant),
                                  ),
                            QuestionBankScreen(
                              entries: _collectQuestionBankEntries(state.quizzes),
                              onCreateQuizFromSelection: (questions) =>
                                  _createQuizFromBankSelection(context, questions),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createQuiz(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.tr(context, 'newQuiz')),
          ),
        );
      },
    );
  }
}
