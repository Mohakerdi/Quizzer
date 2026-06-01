import 'package:flutter/material.dart';

import 'package:adv_basics/core/l10n/app_strings.dart';
import 'package:adv_basics/data/models/quiz_model.dart';

enum _QuizListSortMode {
  title,
  recentlyUpdated,
}

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({
    super.key,
    required this.quizzes,
    required this.selectedQuizId,
    required this.variantCountsByQuizId,
    required this.onCreateQuiz,
    required this.onImportQuiz,
    required this.onSelectQuiz,
    required this.onRenameQuiz,
    required this.onDuplicateQuiz,
    required this.onDeleteQuiz,
  });

  final List<QuizModel> quizzes;
  final String? selectedQuizId;
  final Map<String, int> variantCountsByQuizId;
  final Future<void> Function() onCreateQuiz;
  final Future<void> Function() onImportQuiz;
  final Future<void> Function(QuizModel quiz) onSelectQuiz;
  final Future<void> Function(QuizModel quiz) onRenameQuiz;
  final Future<void> Function(QuizModel quiz) onDuplicateQuiz;
  final Future<void> Function(QuizModel quiz) onDeleteQuiz;

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  _QuizListSortMode _sortMode = _QuizListSortMode.recentlyUpdated;

  List<QuizModel> _sortedQuizzes() {
    final sorted = [...widget.quizzes];
    if (_sortMode == _QuizListSortMode.title) {
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return sorted;
    }

    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = _sortedQuizzes();
    return Column(
      children: [
        ListTile(
          title: Text(AppStrings.tr(context, 'quizzes')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<_QuizListSortMode>(
                icon: const Icon(Icons.sort),
                tooltip: AppStrings.tr(context, 'quizSortMenuTooltip'),
                onSelected: (value) {
                  setState(() => _sortMode = value);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _QuizListSortMode.recentlyUpdated,
                    child: Text(AppStrings.tr(context, 'sortMostRecentlyUpdated')),
                  ),
                  PopupMenuItem(
                    value: _QuizListSortMode.title,
                    child: Text(AppStrings.tr(context, 'sortTitle')),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: widget.onImportQuiz,
                tooltip: AppStrings.tr(context, 'importQuizTooltip'),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: widget.onCreateQuiz,
                tooltip: AppStrings.tr(context, 'createQuizTooltip'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: quizzes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.tr(context, 'noQuizzesYet'),
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.tr(context, 'quizListEmptyDescription'),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: widget.onCreateQuiz,
                          icon: const Icon(Icons.add),
                          label: Text(AppStrings.tr(context, 'createQuiz')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final selected = quiz.id == widget.selectedQuizId;
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;
                    final variantCount = widget.variantCountsByQuizId[quiz.id] ?? 0;

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
                                    ? '${quiz.questions.length} سؤال · $variantCount نموذج · ن${quiz.version}'
                                    : '${quiz.questions.length} question(s) · $variantCount variant(s) · v${quiz.version}',
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
                          onTap: () => widget.onSelectQuiz(quiz),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                await widget.onRenameQuiz(quiz);
                              }
                              if (value == 'duplicate') {
                                await widget.onDuplicateQuiz(quiz);
                              }
                              if (value == 'delete') {
                                await widget.onDeleteQuiz(quiz);
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
