import 'package:flutter/material.dart';

import 'package:adv_basics/l10n/app_strings.dart';
import 'package:adv_basics/models/quiz_question.dart';
import 'package:adv_basics/widgets/math_or_text.dart';

class BankQuestionEntry {
  const BankQuestionEntry({
    required this.quizId,
    required this.quizTitle,
    required this.question,
  });

  final String quizId;
  final String quizTitle;
  final QuizQuestion question;

  String get selectionKey => '$quizId:${question.id}';
}

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({
    super.key,
    required this.entries,
    required this.onCreateQuizFromSelection,
  });

  final List<BankQuestionEntry> entries;
  final Future<void> Function(List<QuizQuestion> questions) onCreateQuizFromSelection;

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

  List<BankQuestionEntry> _filteredEntries() {
    return widget.entries.where((entry) {
      return _matchesFilter(entry.question.gradeLevel, _gradeController.text) &&
          _matchesFilter(entry.question.unitOfStudy, _unitController.text) &&
          _matchesFilter(entry.question.curriculum, _curriculumController.text);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries();
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
          Row(
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
                          _selectedQuestionIds.addAll(filtered.map((entry) => entry.selectionKey));
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
                        final selectedQuestions = widget.entries
                            .where((entry) => _selectedQuestionIds.contains(entry.selectionKey))
                            .map((entry) => entry.question)
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
                      final entry = filtered[index];
                      final question = entry.question;
                      return Card(
                        child: CheckboxListTile(
                          value: _selectedQuestionIds.contains(entry.selectionKey),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedQuestionIds.add(entry.selectionKey);
                              } else {
                                _selectedQuestionIds.remove(entry.selectionKey);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: MathOrText(question.composedPrompt),
                          subtitle: Text(
                            '${AppStrings.tr(context, 'gradeLevel')}: ${question.gradeLevel.isEmpty ? '-' : question.gradeLevel}\n'
                            '${AppStrings.tr(context, 'unitOfStudy')}: ${question.unitOfStudy.isEmpty ? '-' : question.unitOfStudy}\n'
                            '${AppStrings.tr(context, 'curriculum')}: ${question.curriculum.isEmpty ? '-' : question.curriculum}\n'
                            '${AppStrings.tr(context, 'bankQuestionSource')}: ${entry.quizTitle}',
                          ),
                          isThreeLine: true,
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
