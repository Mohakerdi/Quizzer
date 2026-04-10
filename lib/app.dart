import 'package:flutter/material.dart';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/screens/quiz_editor_screen.dart';
import 'package:adv_basics/screens/quiz_list_screen.dart';
import 'package:adv_basics/screens/variant_preview_screen.dart';
import 'package:adv_basics/services/docx_export_service.dart';
import 'package:adv_basics/services/quiz_repository.dart';
import 'package:adv_basics/services/variant_generator.dart';

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
      home: const QuizMakerHome(),
    );
  }
}

class QuizMakerHome extends StatefulWidget {
  const QuizMakerHome({super.key});

  @override
  State<QuizMakerHome> createState() => _QuizMakerHomeState();
}

class _QuizMakerHomeState extends State<QuizMakerHome> {
  final QuizRepository _repository = QuizRepository();
  final VariantGenerator _variantGenerator = const VariantGenerator();
  final DocxExportService _docxExportService = const DocxExportService();

  List<QuizModel> _quizzes = [];
  QuizModel? _selectedQuiz;
  List<GeneratedVariant> _generatedVariants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final quizzes = await _repository.loadQuizzes();
    setState(() {
      _quizzes = quizzes;
      _selectedQuiz = quizzes.isNotEmpty ? quizzes.first : null;
      _isLoading = false;
    });

    if (_selectedQuiz != null) {
      final variants = await _repository.loadVariantsForQuiz(_selectedQuiz!.id);
      setState(() {
        _generatedVariants = variants;
      });
    }
  }

  Future<void> _createQuiz() async {
    final title = await _promptText('Create Quiz', 'Quiz title');
    if (title == null || title.trim().isEmpty) {
      return;
    }

    final created = await _repository.upsertQuiz(QuizModel.empty(title.trim()));

    setState(() {
      _quizzes = [..._quizzes, created];
      _selectedQuiz = created;
      _generatedVariants = [];
    });
  }

  Future<void> _renameQuiz(QuizModel quiz) async {
    final title = await _promptText('Rename Quiz', 'Quiz title', initialText: quiz.title);
    if (title == null || title.trim().isEmpty) {
      return;
    }

    final updated = quiz.copyWith(title: title.trim(), updatedAt: DateTime.now());
    final saved = await _repository.upsertQuiz(updated);

    setState(() {
      _quizzes = _quizzes.map((q) => q.id == saved.id ? saved : q).toList();
      if (_selectedQuiz?.id == saved.id) {
        _selectedQuiz = saved;
      }
    });
  }

  Future<void> _duplicateQuiz(QuizModel quiz) async {
    final duplicated = await _repository.upsertQuiz(quiz.duplicate());

    setState(() {
      _quizzes = [..._quizzes, duplicated];
    });
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    await _repository.deleteQuiz(quiz.id);
    await _repository.deleteVariantsForQuiz(quiz.id);

    setState(() {
      _quizzes = _quizzes.where((q) => q.id != quiz.id).toList();
      if (_selectedQuiz?.id == quiz.id) {
        _selectedQuiz = _quizzes.isNotEmpty ? _quizzes.first : null;
        _generatedVariants = [];
      }
    });

    if (_selectedQuiz != null) {
      _generatedVariants = await _repository.loadVariantsForQuiz(_selectedQuiz!.id);
      setState(() {});
    }
  }

  Future<void> _selectQuiz(QuizModel quiz) async {
    final variants = await _repository.loadVariantsForQuiz(quiz.id);
    setState(() {
      _selectedQuiz = quiz;
      _generatedVariants = variants;
    });
  }

  Future<void> _saveQuiz(QuizModel quiz) async {
    final saved = await _repository.upsertQuiz(quiz);
    setState(() {
      _quizzes = _quizzes.map((q) => q.id == saved.id ? saved : q).toList();
      _selectedQuiz = saved;
    });
  }

  Future<void> _generateVariants(QuizModel quiz) async {
    final countText = await _promptText('Generate Variants', 'How many versions?', initialText: '2');
    if (countText == null) {
      return;
    }

    final count = int.tryParse(countText);
    if (count == null || count < 1) {
      _showSnack('Please enter a valid number of variants.');
      return;
    }

    final variants = _variantGenerator.generate(quiz: quiz, count: count);
    await _repository.saveVariantsForQuiz(quiz.id, variants);

    setState(() {
      _generatedVariants = variants;
    });

    _showSnack('Generated ${variants.length} variant(s).');
  }

  Future<void> _previewVariant(GeneratedVariant variant) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VariantPreviewScreen(variant: variant),
      ),
    );
  }

  Future<void> _exportVariant(GeneratedVariant variant) async {
    final quiz = _selectedQuiz;
    if (quiz == null) {
      return;
    }

    final quizDocPath = await _docxExportService.exportQuizPaper(quiz: quiz, variant: variant);
    final solutionDocPath = await _docxExportService.exportSolutions(quiz: quiz, variant: variant);

    _showSnack('Exported:\n$quizDocPath\n$solutionDocPath');
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<String?> _promptText(String title, String hint, {String initialText = ''}) async {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
              quizzes: _quizzes,
              selectedQuizId: _selectedQuiz?.id,
              onCreateQuiz: _createQuiz,
              onSelectQuiz: _selectQuiz,
              onRenameQuiz: _renameQuiz,
              onDuplicateQuiz: _duplicateQuiz,
              onDeleteQuiz: _deleteQuiz,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedQuiz == null
                ? const Center(child: Text('Create or select a quiz to start.'))
                : QuizEditorScreen(
                    quiz: _selectedQuiz!,
                    generatedVariants: _generatedVariants,
                    onQuizChanged: _saveQuiz,
                    onGenerateVariants: _generateVariants,
                    onPreviewVariant: _previewVariant,
                    onExportVariant: _exportVariant,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQuiz,
        icon: const Icon(Icons.add),
        label: const Text('New Quiz'),
      ),
    );
  }
}
