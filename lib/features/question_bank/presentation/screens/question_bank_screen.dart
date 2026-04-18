import 'package:flutter/material.dart';

import 'package:adv_basics/core/l10n/app_strings.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:adv_basics/core/widgets/math_or_text.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({
    super.key,
    required this.questions,
    required this.onCreateQuizFromSelection,
    required this.onDuplicateQuestion,
    required this.onDeleteQuestion,
  });

  final List<QuizQuestion> questions;
  final Future<void> Function(List<QuizQuestion> questions) onCreateQuizFromSelection;
  final Future<void> Function(QuizQuestion question) onDuplicateQuestion;
  final Future<void> Function(QuizQuestion question) onDeleteQuestion;

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final _gradeController = TextEditingController();
  final _unitController = TextEditingController();
  final _curriculumController = TextEditingController();
  final Set<String> _selectedQuestionIds = <String>{};

  @override
  void dispose() {
    _gradeController.dispose();
    _unitController.dispose();
    _curriculumController.dispose();
    super.dispose();
  }

  bool _matchesFilter(String source, String filter) {
    final normalizedFilter = filter.trim().toLowerCase();
    if (normalizedFilter.isEmpty) {
      return true;
    }
    return source.toLowerCase().contains(normalizedFilter);
  }

  List<QuizQuestion> _filteredQuestions() {
    return widget.questions.where((question) {
      return _matchesFilter(question.gradeLevel, _gradeController.text) &&
          _matchesFilter(question.unitOfStudy, _unitController.text) &&
          _matchesFilter(question.curriculum, _curriculumController.text);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredQuestions();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.tr(context, 'filterQuestions'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compactLayout = constraints.maxWidth < 700;
              if (compactLayout) {
                return Column(
                  children: [
                    TextField(
                      controller: _gradeController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: AppStrings.tr(context, 'gradeLevel'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _unitController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: AppStrings.tr(context, 'unitOfStudy'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _curriculumController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: AppStrings.tr(context, 'curriculum'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gradeController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: AppStrings.tr(context, 'gradeLevel'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: AppStrings.tr(context, 'unitOfStudy'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _curriculumController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: AppStrings.tr(context, 'curriculum'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: filtered.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _selectedQuestionIds.addAll(filtered.map((question) => question.id));
                        });
                      },
                icon: const Icon(Icons.select_all),
                label: Text(AppStrings.tr(context, 'selectAllVisible')),
              ),
              TextButton(
                onPressed: _selectedQuestionIds.isEmpty
                    ? null
                    : () {
                        setState(_selectedQuestionIds.clear);
                      },
                child: Text(AppStrings.tr(context, 'clearSelection')),
              ),
              Text(
                '${AppStrings.tr(context, 'selectedCount')}: ${_selectedQuestionIds.length}',
              ),
              FilledButton.icon(
                onPressed: _selectedQuestionIds.isEmpty
                    ? null
                    : () async {
                        final selectedQuestions = widget.questions
                            .where((question) => _selectedQuestionIds.contains(question.id))
                            .toList();
                        await widget.onCreateQuizFromSelection(selectedQuestions);
                      },
                icon: const Icon(Icons.auto_awesome),
                label: Text(AppStrings.tr(context, 'createQuizFromSelection')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(AppStrings.tr(context, 'questionBankEmpty')))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                       final question = filtered[index];
                       return Card(
                         child: ListTile(
                           leading: Checkbox(
                             value: _selectedQuestionIds.contains(question.id),
                             onChanged: (checked) {
                               setState(() {
                                 if (checked == true) {
                                   _selectedQuestionIds.add(question.id);
                                 } else {
                                   _selectedQuestionIds.remove(question.id);
                                 }
                               });
                             },
                           ),
                           title: MathOrText(question.composedPrompt),
                           subtitle: Text(
                             '${AppStrings.tr(context, 'gradeLevel')}: ${question.gradeLevel.isEmpty ? '-' : question.gradeLevel}\n'
                             '${AppStrings.tr(context, 'unitOfStudy')}: ${question.unitOfStudy.isEmpty ? '-' : question.unitOfStudy}\n'
                             '${AppStrings.tr(context, 'curriculum')}: ${question.curriculum.isEmpty ? '-' : question.curriculum}',
                           ),
                           isThreeLine: true,
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: AppStrings.tr(context, 'duplicateQuestion'),
                                  icon: const Icon(Icons.copy),
                                  onPressed: () async {
                                    await widget.onDuplicateQuestion(question);
                                  },
                                ),
                                IconButton(
                                  tooltip: AppStrings.tr(context, 'deleteQuestionFromBank'),
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await widget.onDeleteQuestion(question);
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() {
                                      _selectedQuestionIds.remove(question.id);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                  ),
          ),
        ],
      ),
    );
  }
}
