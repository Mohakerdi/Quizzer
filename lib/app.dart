import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/screens/quiz_editor_screen.dart';
import 'package:adv_basics/screens/quiz_list_screen.dart';
import 'package:adv_basics/screens/variant_preview_screen.dart';
import 'package:adv_basics/services/docx_export_service.dart';
import 'package:adv_basics/services/quiz_repository.dart';
import 'package:adv_basics/services/variant_generator.dart';
import 'package:adv_basics/view_models/quiz_maker_cubit.dart';
import 'package:adv_basics/view_models/quiz_maker_state.dart';

class QuizMakerApp extends StatelessWidget {
  const QuizMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quizzer Maker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D3FD3)),
      ),
      home: BlocProvider(
        create: (_) => QuizMakerCubit(
          repository: QuizRepository(),
          variantGenerator: const VariantGenerator(),
          docxExportService: const DocxExportService(),
        )..loadData(),
        child: const QuizMakerHome(),
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _createQuiz(BuildContext context) async {
    final title = await _promptText(context, 'Create Quiz', 'Quiz title');
    if (title == null || title.trim().isEmpty || !context.mounted) {
      return;
    }
    await context.read<QuizMakerCubit>().createQuiz(title.trim());
  }

  Future<void> _renameQuiz(BuildContext context, QuizModel quiz) async {
    final title = await _promptText(
      context,
      'Rename Quiz',
      'Quiz title',
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
      'Generate Variants',
      'How many versions?',
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
        ..showSnackBar(const SnackBar(content: Text('Please enter a valid number of variants.')));
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
            title: const Text('Quizzer Maker'),
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
                child: state.selectedQuiz == null
                    ? const Center(child: Text('Create or select a quiz to start.'))
                    : QuizEditorScreen(
                        quiz: state.selectedQuiz!,
                        generatedVariants: state.generatedVariants,
                        onQuizChanged: (quiz) => context.read<QuizMakerCubit>().saveQuiz(quiz),
                        onGenerateVariants: (quiz) => _generateVariants(context, quiz),
                        onPreviewVariant: (variant) => _previewVariant(context, variant),
                        onExportVariant: (variant) => context.read<QuizMakerCubit>().exportVariant(variant),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createQuiz(context),
            icon: const Icon(Icons.add),
            label: const Text('New Quiz'),
          ),
        );
      },
    );
  }
}
