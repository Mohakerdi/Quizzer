import 'package:flutter/material.dart';

import 'package:adv_basics/core/l10n/app_strings.dart';
import 'package:adv_basics/data/models/quiz_model.dart';

class QuizListScreen extends StatelessWidget {
  const QuizListScreen({
    super.key,
    required this.quizzes,
    required this.selectedQuizId,
    required this.onCreateQuiz,
    required this.onImportQuiz,
    required this.onSelectQuiz,
    required this.onRenameQuiz,
    required this.onDuplicateQuiz,
    required this.onDeleteQuiz,
  });

  final List<QuizModel> quizzes;
  final String? selectedQuizId;
  final Future<void> Function() onCreateQuiz;
  final Future<void> Function() onImportQuiz;
  final Future<void> Function(QuizModel quiz) onSelectQuiz;
  final Future<void> Function(QuizModel quiz) onRenameQuiz;
  final Future<void> Function(QuizModel quiz) onDuplicateQuiz;
  final Future<void> Function(QuizModel quiz) onDeleteQuiz;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(AppStrings.tr(context, 'quizzes')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: onImportQuiz,
                tooltip: AppStrings.tr(context, 'importQuizTooltip'),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onCreateQuiz,
                tooltip: AppStrings.tr(context, 'createQuizTooltip'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: quizzes.isEmpty
              ? Center(child: Text(AppStrings.tr(context, 'noQuizzesYet')))
              : ListView.builder(
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final selected = quiz.id == selectedQuizId;
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;

                    final ar = AppStrings.isArabic(context);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Material(
                        color: selected ? colorScheme.primaryContainer : colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          selected: selected,
                          leading: Icon(
                            selected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: selected ? colorScheme.primary : colorScheme.outline,
                          ),
                          title: Text(
                            quiz.title,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ar
                                    ? '${quiz.questions.length} سؤال · ن${quiz.version}'
                                    : '${quiz.questions.length} question(s) · v${quiz.version}',
                              ),
                              if (selected)
                                Text(
                                  AppStrings.tr(context, 'selectedQuiz'),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => onSelectQuiz(quiz),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                await onRenameQuiz(quiz);
                              }
                              if (value == 'duplicate') {
                                await onDuplicateQuiz(quiz);
                              }
                              if (value == 'delete') {
                                await onDeleteQuiz(quiz);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'rename', child: Text(AppStrings.tr(context, 'rename'))),
                              PopupMenuItem(value: 'duplicate', child: Text(AppStrings.tr(context, 'duplicate'))),
                              PopupMenuItem(value: 'delete', child: Text(AppStrings.tr(context, 'delete'))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
