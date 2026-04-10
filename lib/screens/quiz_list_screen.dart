import 'package:flutter/material.dart';

import 'package:adv_basics/l10n/app_strings.dart';
import 'package:adv_basics/models/quiz_model.dart';

class QuizListScreen extends StatelessWidget {
  const QuizListScreen({
    super.key,
    required this.quizzes,
    required this.selectedQuizId,
    required this.onCreateQuiz,
    required this.onSelectQuiz,
    required this.onRenameQuiz,
    required this.onDuplicateQuiz,
    required this.onDeleteQuiz,
  });

  final List<QuizModel> quizzes;
  final String? selectedQuizId;
  final Future<void> Function() onCreateQuiz;
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
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: onCreateQuiz,
            tooltip: AppStrings.tr(context, 'createQuizTooltip'),
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

                    final ar = AppStrings.isArabic(context);
                    return ListTile(
                      selected: selected,
                      title: Text(quiz.title),
                      subtitle: Text(
                        ar
                            ? '${quiz.questions.length} سؤال · ن${quiz.version}'
                            : '${quiz.questions.length} question(s) · v${quiz.version}',
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
                    );
                  },
                ),
        ),
      ],
    );
  }
}
