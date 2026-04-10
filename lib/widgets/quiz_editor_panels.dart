import 'package:flutter/material.dart';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_question.dart';

class QuizEditorActionsBar extends StatelessWidget {
  const QuizEditorActionsBar({
    super.key,
    required this.onSave,
    required this.onValidate,
    required this.onAddQuestion,
    required this.onGenerateVariants,
  });

  final VoidCallback onSave;
  final VoidCallback onValidate;
  final VoidCallback onAddQuestion;
  final VoidCallback onGenerateVariants;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save),
          label: const Text('Save Quiz'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onValidate,
          icon: const Icon(Icons.rule),
          label: const Text('Validate'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onAddQuestion,
          icon: const Icon(Icons.add),
          label: const Text('Add Question'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onGenerateVariants,
          icon: const Icon(Icons.shuffle),
          label: const Text('Generate Variants'),
        ),
      ],
    );
  }
}

class QuizQuestionsPanel extends StatelessWidget {
  const QuizQuestionsPanel({
    super.key,
    required this.questions,
    required this.onMoveQuestion,
    required this.onEditQuestion,
    required this.onRemoveQuestion,
  });

  final List<QuizQuestion> questions;
  final void Function(int index, int direction) onMoveQuestion;
  final void Function(int index) onEditQuestion;
  final void Function(int index) onRemoveQuestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return ListTile(
            title: Text('Q${index + 1}: ${question.composedPrompt}'),
            subtitle: Text('Options: ${question.options.length}'),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: () => onMoveQuestion(index, -1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: () => onMoveQuestion(index, 1),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEditQuestion(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: questions.length <= 1 ? null : () => onRemoveQuestion(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GeneratedVariantsPanel extends StatelessWidget {
  const GeneratedVariantsPanel({
    super.key,
    required this.generatedVariants,
    required this.onPreviewVariant,
    required this.onExportVariant,
  });

  final List<GeneratedVariant> generatedVariants;
  final Future<void> Function(GeneratedVariant variant) onPreviewVariant;
  final Future<void> Function(GeneratedVariant variant) onExportVariant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Generated Variants', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: generatedVariants.isEmpty
                  ? const Center(child: Text('No variants generated yet.'))
                  : ListView.builder(
                      itemCount: generatedVariants.length,
                      itemBuilder: (context, index) {
                        final variant = generatedVariants[index];
                        return ListTile(
                          title: Text(variant.id),
                          subtitle: Text('${variant.questions.length} question(s)'),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Preview',
                                icon: const Icon(Icons.visibility),
                                onPressed: () => onPreviewVariant(variant),
                              ),
                              IconButton(
                                tooltip: 'Export DOCX',
                                icon: const Icon(Icons.download),
                                onPressed: () => onExportVariant(variant),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
