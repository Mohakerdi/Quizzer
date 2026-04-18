import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:adv_basics/core/l10n/app_strings.dart';
import 'package:adv_basics/core/theme/app_theme.dart';
import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/features/question_bank/presentation/screens/question_bank_screen.dart';
import 'package:adv_basics/features/quiz_maker/presentation/screens/quiz_editor_screen.dart';
import 'package:adv_basics/features/quiz_list/presentation/screens/quiz_list_screen.dart';
import 'package:adv_basics/features/variant_preview/presentation/screens/variant_preview_screen.dart';
import 'package:adv_basics/core/application/app_settings_cubit.dart';
import 'package:adv_basics/core/application/app_settings_state.dart';
import 'package:adv_basics/core/di/app_dependencies.dart';
import 'package:adv_basics/features/quiz_maker/application/quiz_session_cubit.dart';
import 'package:adv_basics/features/quiz_maker/application/quiz_session_state.dart';

class QuizMakerApp extends StatelessWidget {
  const QuizMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.create();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AppSettingsCubit(
            localDataSource: dependencies.appSettingsLocalDataSource,
          ),
        ),
        BlocProvider(
          create: (_) => QuizSessionCubit(
            repository: dependencies.quizRepository,
            createQuizUseCase: dependencies.createQuizUseCase,
            importQuizFromJsonUseCase: dependencies.importQuizFromJsonUseCase,
            createQuizFromQuestionBankUseCase: dependencies.createQuizFromQuestionBankUseCase,
            renameQuizUseCase: dependencies.renameQuizUseCase,
            duplicateQuizUseCase: dependencies.duplicateQuizUseCase,
            generateVariantsUseCase: dependencies.generateVariantsUseCase,
            exportVariantUseCase: dependencies.exportVariantUseCase,
            exportAllVariantsUseCase: dependencies.exportAllVariantsUseCase,
            exportVariantToGoogleFormsUseCase: dependencies.exportVariantToGoogleFormsUseCase,
          )..loadData(),
        ),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, appConfig) => MaterialApp(
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
        ),
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
  static const _githubUrl = 'https://github.com/Mohakerdi';
  static const _linkedinUrl = 'https://www.linkedin.com/in/mohammad-kerdi-733126364';
  static const _telegramUrl = 'https://t.me/MOHA_KRDI';
  static const _importQuizTemplateJson = '''
{
  "title": "My Imported Quiz",
  "createdAt": "2026-04-16T20:00:00Z",
  "updatedAt": "2026-04-16T20:00:00Z",
  "questions": [
    {
      "text": "Solve the equation",
      "math": "\\\\frac{1}{2}x + 3 = 7",
      "imageRef": "",
      "topic": "Algebra",
      "difficulty": "Medium",
      "gradeLevel": "8",
      "unitOfStudy": "Linear Equations",
      "curriculum": "Math",
      "correctOptionId": "opt-1",
      "options": [
        {
          "id": "opt-1",
          "text": "x = 8",
          "math": "",
          "isCorrect": true
        },
        {
          "id": "opt-2",
          "text": "x = 4",
          "math": "",
          "isCorrect": false
        }
      ]
    }
  ]
}
''';
  final GlobalKey _languageButtonKey = GlobalKey();
  final GlobalKey _newQuizFabKey = GlobalKey();
  final GlobalKey _questionBankTabKey = GlobalKey();

  Future<void> _maybeShowArabicTutorial() async {
    final shouldShow = await context.read<AppSettingsCubit>().showArabicTutorialIfNeeded();
    if (!shouldShow || !mounted) {
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

  TargetContent _buildArabicTargetContent({
    required String title,
    required String description,
  }) {
    return TargetContent(
      align: ContentAlign.bottom,
      child:  Directionality(
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
    await context.read<QuizSessionCubit>().createQuiz(title.trim());
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

    await context.read<QuizSessionCubit>().renameQuiz(quiz: quiz, title: title.trim());
  }

  Future<void> _importQuizFromJson(BuildContext context) async {
    final jsonController = TextEditingController();
    final jsonToImport = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(AppStrings.tr(context, 'importQuiz'))),
            IconButton(
              tooltip: AppStrings.tr(context, 'importTemplateInfoTooltip'),
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showImportTemplateDialog(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: jsonController,
            minLines: 10,
            maxLines: 18,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: AppStrings.tr(context, 'importQuizJsonLabel'),
              hintText: AppStrings.tr(context, 'importQuizJsonHint'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr(context, 'cancel')),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop(jsonController.text.trim());
            },
            icon: const Icon(Icons.upload_file),
            label: Text(AppStrings.tr(context, 'import')),
          ),
        ],
      ),
    );
    jsonController.dispose();

    if (jsonToImport == null || jsonToImport.isEmpty || !context.mounted) {
      return;
    }

    await context.read<QuizSessionCubit>().importQuizFromJson(
          rawJson: jsonToImport,
          isArabic: AppStrings.isArabic(context),
        );
  }

  Future<void> _showImportTemplateDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr(context, 'importTemplateTitle')),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppStrings.tr(context, 'importTemplateDescription')),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: SelectableText(_importQuizTemplateJson),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr(context, 'close')),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: _importQuizTemplateJson));
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(content: Text(AppStrings.tr(context, 'importTemplateCopied'))));
            },
            icon: const Icon(Icons.copy),
            label: Text(AppStrings.tr(context, 'copyTemplate')),
          ),
        ],
      ),
    );
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
    await context.read<QuizSessionCubit>().generateVariants(
          quiz: quiz,
          count: count,
          isArabic: AppStrings.isArabic(context),
        );
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
    await context.read<QuizSessionCubit>().createQuizFromQuestionBank(
          title: title.trim(),
          questions: selectedQuestions,
          isArabic: AppStrings.isArabic(context),
        );
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(AppStrings.tr(context, 'openLinkError'))));
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr(context, 'aboutTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.tr(context, 'aboutTeacherMessage')),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _openExternalUrl(context, _githubUrl),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(AppStrings.tr(context, 'githubProfile')),
            ),
            TextButton.icon(
              onPressed: () => _openExternalUrl(context, _linkedinUrl),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(AppStrings.tr(context, 'linkedinProfile')),
            ),
            TextButton.icon(
              onPressed: () => _openExternalUrl(context, _telegramUrl),
              icon: const Icon(Icons.telegram, size: 18),
              label: Text(AppStrings.tr(context, 'telegramProfile')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr(context, 'close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizSessionCubit, QuizSessionState>(
      listenWhen: (previous, current) => previous.message != current.message,
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.quizzes != current.quizzes ||
          previous.selectedQuiz != current.selectedQuiz ||
          previous.generatedVariants != current.generatedVariants ||
          previous.questionBank != current.questionBank,
      listener: (context, state) {
        final message = state.message;
        if (message == null || message.isEmpty) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));

        context.read<QuizSessionCubit>().clearMessage();
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
                themeMode: context.watch<AppSettingsCubit>().state.themeMode,
                onToggleTheme: () => context.read<AppSettingsCubit>().toggleThemeMode(),
                onSetLocale: (locale) => context.read<AppSettingsCubit>().setLocale(locale),
                onShowInfo: () => _showInfoDialog(context),
                languageButtonKey: _languageButtonKey,
              ),
            ],
          ),
          body: _HomeWorkspace(
            state: state,
            onCreateQuiz: () => _createQuiz(context),
            onImportQuiz: () => _importQuizFromJson(context),
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
    required this.onShowInfo,
    required this.languageButtonKey,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<Locale> onSetLocale;
  final VoidCallback onShowInfo;
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
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: AppStrings.tr(context, 'aboutInfo'),
          onPressed: onShowInfo,
        ),
      ],
    );
  }
}

class _HomeWorkspace extends StatelessWidget {
  const _HomeWorkspace({
    required this.state,
    required this.onCreateQuiz,
    required this.onImportQuiz,
    required this.onRenameQuiz,
    required this.onGenerateVariants,
    required this.onPreviewVariant,
    required this.onCreateQuizFromBankSelection,
    required this.questionBankTabKey,
  });

  final QuizSessionState state;
  final Future<void> Function() onCreateQuiz;
  final Future<void> Function() onImportQuiz;
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
            onImportQuiz: onImportQuiz,
            onSelectQuiz: (quiz) => context.read<QuizSessionCubit>().selectQuiz(quiz),
            onRenameQuiz: onRenameQuiz,
            onDuplicateQuiz: (quiz) => context.read<QuizSessionCubit>().duplicateQuiz(quiz),
            onDeleteQuiz: (quiz) => context.read<QuizSessionCubit>().deleteQuiz(quiz),
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
                              onQuizChanged: (quiz) => context.read<QuizSessionCubit>().saveQuiz(quiz),
                              onQuizAutoSave: (quiz) => context.read<QuizSessionCubit>().saveQuizSilently(quiz),
                              onGenerateVariants: onGenerateVariants,
                              onPreviewVariant: onPreviewVariant,
                               onExportVariant:
                                   (variant, {teacherName, schoolName, exportLanguageCode, optionLabelStyle}) => context
                                    .read<QuizSessionCubit>()
                                    .exportVariant(
                                    variant,
                                    teacherName: teacherName,
                                    schoolName: schoolName,
                                     exportLanguageCode: exportLanguageCode,
                                     optionLabelStyle: optionLabelStyle,
                                   ),
                               onExportAllVariants:
                                   ({teacherName, schoolName, exportLanguageCode, optionLabelStyle}) => context
                                    .read<QuizSessionCubit>()
                                    .exportAllVariants(
                                      isArabic: AppStrings.isArabic(context),
                                      teacherName: teacherName,
                                      schoolName: schoolName,
                                      exportLanguageCode: exportLanguageCode,
                                      optionLabelStyle: optionLabelStyle,
                                    ),
                                onExportGoogleForms:
                                    (variant) => context.read<QuizSessionCubit>().exportVariantToGoogleForms(variant),
                                onAddQuestionToBank:
                                    (question) => context.read<QuizSessionCubit>().addQuestionToQuestionBank(
                                          question: question,
                                          isArabic: AppStrings.isArabic(context),
                                        ),
                              ),
                        QuestionBankScreen(
                          questions: state.questionBank,
                          onCreateQuizFromSelection: onCreateQuizFromBankSelection,
                          onDuplicateQuestion:
                              (question) => context.read<QuizSessionCubit>().duplicateQuestionInQuestionBank(
                                    question: question,
                                    isArabic: AppStrings.isArabic(context),
                                  ),
                          onDeleteQuestion: (question) =>
                              context.read<QuizSessionCubit>().deleteQuestionFromQuestionBank(
                                bankQuestionId: question.id,
                                isArabic: AppStrings.isArabic(context),
                              ),
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
