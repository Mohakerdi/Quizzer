import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:adv_basics/core/l10n/app_strings.dart';
import 'package:adv_basics/core/theme/app_theme.dart';
import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/features/question_bank/presentation/screens/question_bank_screen.dart';
import 'package:adv_basics/features/quiz_maker/presentation/screens/quiz_editor_screen.dart';
import 'package:adv_basics/features/quiz_list/presentation/screens/quiz_list_screen.dart';
import 'package:adv_basics/features/variant_preview/presentation/screens/variant_preview_screen.dart';
import 'package:adv_basics/data/services/docx_export_service.dart';
import 'package:adv_basics/data/services/google_forms_export_service.dart';
import 'package:adv_basics/data/repositories/quiz_repository.dart';
import 'package:adv_basics/features/quiz_maker/domain/services/variant_generator.dart';
import 'package:adv_basics/features/quiz_maker/application/quiz_maker_cubit.dart';
import 'package:adv_basics/features/quiz_maker/application/quiz_maker_state.dart';

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
      child: BlocSelector<QuizMakerCubit, QuizMakerState, ({Locale locale, ThemeMode themeMode})>(
        selector: (state) => (locale: state.locale, themeMode: state.themeMode),
        builder: (context, appConfig) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Quizzer Maker',
            locale: appConfig.locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: appConfig.themeMode,
            home: const QuizMakerHome(),
          );
        },
      ),
    );
  }
}

class QuizMakerHome extends StatefulWidget {
  const QuizMakerHome({super.key});

  @override
  State<QuizMakerHome> createState() => _QuizMakerHomeState();
}

class _QuizMakerHomeState extends State<QuizMakerHome> {
  static const _tutorialSeenKey = 'quizzer_arabic_tutorial_seen_v1';
  final GlobalKey _languageButtonKey = GlobalKey();
  final GlobalKey _newQuizFabKey = GlobalKey();
  final GlobalKey _questionBankTabKey = GlobalKey();
  bool _checkedTutorial = false;

  Future<void> _maybeShowArabicTutorial() async {
    if (_checkedTutorial) {
      return;
    }
    _checkedTutorial = true;
    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool(_tutorialSeenKey) ?? false;
    if (alreadySeen || !mounted) {
      return;
    }

    await prefs.setBool(_tutorialSeenKey, true);
    if (!mounted) {
      return;
    }

    final targets = <TargetFocus>[
      TargetFocus(
        keyTarget: _languageButtonKey,
        contents: [
          _buildArabicTargetContent(
            title: 'تغيير اللغة',
            description: 'من هنا يمكنك التبديل بين العربية والإنجليزية.',
          ),
        ],
      ),
      TargetFocus(
        keyTarget: _newQuizFabKey,
        contents: [
          _buildArabicTargetContent(
            title: 'اختبار جديد',
            description: 'ابدأ بإنشاء اختبار جديد من هذا الزر.',
          ),
        ],
      ),
      TargetFocus(
        keyTarget: _questionBankTabKey,
        contents: [
          _buildArabicTargetContent(
            title: 'بنك الأسئلة',
            description: 'استخدم بنك الأسئلة لإعادة استخدام الأسئلة بسرعة.',
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      textSkip: 'تخطي',
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      onSkip: () => true,
    ).show(context: context);
  }

  ContentTarget _buildArabicTargetContent({
    required String title,
    required String description,
  }) {
    return ContentTarget(
      align: ContentAlign.bottom,
      child: (context, controller) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.quizzes != current.quizzes ||
          previous.selectedQuiz != current.selectedQuiz ||
          previous.generatedVariants != current.generatedVariants ||
          previous.questionBank != current.questionBank ||
          previous.locale != current.locale ||
          previous.themeMode != current.themeMode,
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowArabicTutorial();
        });

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/quiz-logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Text(AppStrings.tr(context, 'appTitle')),
              ],
            ),
            flexibleSpace: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? const [Color(0x6620396D), Color(0x333F85F5)]
                      : const [Color(0x55AEE9FF), Color(0x4499B7FF)],
                ),
              ),
            ),
            actions: [
              _AppBarActions(
                themeMode: state.themeMode,
                onToggleTheme: () => context.read<QuizMakerCubit>().toggleThemeMode(),
                onSetLocale: (locale) => context.read<QuizMakerCubit>().setLocale(locale),
                languageButtonKey: _languageButtonKey,
              ),
            ],
          ),
          body: _HomeWorkspace(
            state: state,
            onCreateQuiz: () => _createQuiz(context),
            onRenameQuiz: (quiz) => _renameQuiz(context, quiz),
            onGenerateVariants: (quiz) => _generateVariants(context, quiz),
            onPreviewVariant: (variant) => _previewVariant(context, variant),
            onCreateQuizFromBankSelection: (questions) => _createQuizFromBankSelection(context, questions),
            questionBankTabKey: _questionBankTabKey,
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: _newQuizFabKey,
            onPressed: () => _createQuiz(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.tr(context, 'newQuiz')),
          ),
        );
      },
    );
  }
}

class _AppBarActions extends StatelessWidget {
  const _AppBarActions({
    required this.themeMode,
    required this.onToggleTheme,
    required this.onSetLocale,
    required this.languageButtonKey,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<Locale> onSetLocale;
  final GlobalKey languageButtonKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
          tooltip: themeMode == ThemeMode.dark
              ? AppStrings.tr(context, 'themeLight')
              : AppStrings.tr(context, 'themeDark'),
          onPressed: onToggleTheme,
        ),
        PopupMenuButton<Locale>(
          key: languageButtonKey,
          icon: const Icon(Icons.language),
          onSelected: onSetLocale,
          itemBuilder: (context) => const [
            PopupMenuItem(value: Locale('en'), child: Text('English')),
            PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
          ],
        ),
      ],
    );
  }
}

class _HomeWorkspace extends StatelessWidget {
  const _HomeWorkspace({
    required this.state,
    required this.onCreateQuiz,
    required this.onRenameQuiz,
    required this.onGenerateVariants,
    required this.onPreviewVariant,
    required this.onCreateQuizFromBankSelection,
    required this.questionBankTabKey,
  });

  final QuizMakerState state;
  final Future<void> Function() onCreateQuiz;
  final Future<void> Function(QuizModel quiz) onRenameQuiz;
  final Future<void> Function(QuizModel quiz) onGenerateVariants;
  final Future<void> Function(GeneratedVariant variant) onPreviewVariant;
  final Future<void> Function(List<QuizQuestion> questions) onCreateQuizFromBankSelection;
  final GlobalKey questionBankTabKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 340,
          child: QuizListScreen(
            quizzes: state.quizzes,
            selectedQuizId: state.selectedQuiz?.id,
            onCreateQuiz: onCreateQuiz,
            onSelectQuiz: (quiz) => context.read<QuizMakerCubit>().selectQuiz(quiz),
            onRenameQuiz: onRenameQuiz,
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
                    Tab(key: questionBankTabKey, text: AppStrings.tr(context, 'questionBankTab')),
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
                              onGenerateVariants: onGenerateVariants,
                              onPreviewVariant: onPreviewVariant,
                              onExportVariant:
                                  (variant, {teacherName, schoolName, exportLanguageCode, optionLabelStyle}) => context
                                  .read<QuizMakerCubit>()
                                  .exportVariant(
                                    variant,
                                    teacherName: teacherName,
                                    schoolName: schoolName,
                                    exportLanguageCode: exportLanguageCode,
                                    optionLabelStyle: optionLabelStyle,
                                  ),
                              onExportGoogleForms:
                                  (variant) => context.read<QuizMakerCubit>().exportVariantToGoogleForms(variant),
                              onAddQuestionToBank:
                                  (question) => context.read<QuizMakerCubit>().addQuestionToQuestionBank(question),
                            ),
                      QuestionBankScreen(
                        questions: state.questionBank,
                        onCreateQuizFromSelection: onCreateQuizFromBankSelection,
                        onDeleteQuestion: (question) =>
                            context.read<QuizMakerCubit>().deleteQuestionFromQuestionBank(question.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
