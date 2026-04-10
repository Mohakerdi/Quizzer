import 'package:flutter/material.dart';

import 'package:adv_basics/l10n/app_strings.dart';
import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_question.dart';
import 'package:adv_basics/widgets/math_or_text.dart';

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
          label: Text(AppStrings.tr(context, 'saveQuiz')),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onValidate,
          icon: const Icon(Icons.rule),
          label: Text(AppStrings.tr(context, 'validate')),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onAddQuestion,
          icon: const Icon(Icons.add),
          label: Text(AppStrings.tr(context, 'addQuestion')),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onGenerateVariants,
          icon: const Icon(Icons.shuffle),
          label: Text(AppStrings.tr(context, 'generateVariants')),
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
            title: Row(
              children: [
                Text('Q${index + 1}: '),
                Expanded(
                  child: MathOrText(
                    question.composedPrompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              AppStrings.isArabic(context)
                  ? 'الخيارات: ${question.options.length}'
                  : 'Options: ${question.options.length}',
            ),
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
    required this.onExportGoogleForms,
  });

  final List<GeneratedVariant> generatedVariants;
  final Future<void> Function(GeneratedVariant variant) onPreviewVariant;
  final Future<void> Function(GeneratedVariant variant) onExportVariant;
  final Future<void> Function(GeneratedVariant variant) onExportGoogleForms;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.tr(context, 'generatedVariantsTitle'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: generatedVariants.isEmpty
                  ? Center(child: Text(AppStrings.tr(context, 'noVariantsYet')))
                  : ListView.builder(
                      itemCount: generatedVariants.length,
                      itemBuilder: (context, index) {
                        final variant = generatedVariants[index];
                        return ListTile(
                          title: Text(variant.id),
                          subtitle: Text(
                            AppStrings.isArabic(context)
                                ? '${variant.questions.length} سؤال'
                                : '${variant.questions.length} question(s)',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: AppStrings.tr(context, 'preview'),
                                icon: const Icon(Icons.visibility),
                                onPressed: () => onPreviewVariant(variant),
                              ),
                              IconButton(
                                tooltip: AppStrings.tr(context, 'exportDocx'),
                                icon: const Icon(Icons.download),
                                onPressed: () => onExportVariant(variant),
                              ),
                              IconButton(
                                tooltip: AppStrings.tr(context, 'exportGoogleForms'),
                                icon: const Icon(Icons.dynamic_form_outlined),
                                onPressed: () => onExportGoogleForms(variant),
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
