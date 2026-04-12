import 'dart:convert';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_model.dart';
import 'package:adv_basics/models/quiz_question.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizRepository {
  static const _quizzesKey = 'quizzer_quizzes_v1';
  static const _variantsKey = 'quizzer_variants_v1';
  static const _questionBankKey = 'quizzer_question_bank_v1';

  Future<List<QuizModel>> loadQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quizzesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => QuizModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<QuizModel> upsertQuiz(QuizModel quiz) async {
    final all = await loadQuizzes();
    final existingIndex = all.indexWhere((q) => q.id == quiz.id);
    final updatedQuiz = quiz.copyWith(
      version: quiz.version + 1,
      updatedAt: DateTime.now(),
    );

    if (existingIndex >= 0) {
      all[existingIndex] = updatedQuiz;
    } else {
      all.add(updatedQuiz);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _quizzesKey,
      jsonEncode(all.map((q) => q.toJson()).toList()),
    );
    return updatedQuiz;
  }

  Future<void> deleteQuiz(String quizId) async {
    final all = await loadQuizzes();
    final kept = all.where((q) => q.id != quizId).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizzesKey, jsonEncode(kept.map((q) => q.toJson()).toList()));
  }

  Future<List<QuizQuestion>> loadQuestionBank() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_questionBankKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> saveQuestionBank(List<QuizQuestion> questions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _questionBankKey,
      jsonEncode(questions.map((q) => q.toJson()).toList()),
    );
  }

  Future<QuizQuestion> upsertQuestionBankQuestion(QuizQuestion question) async {
    final all = await loadQuestionBank();
    final existingIndex = all.indexWhere((q) => q.id == question.id);
    if (existingIndex >= 0) {
      all[existingIndex] = question;
    } else {
      all.add(question);
    }
    await saveQuestionBank(all);
    return question;
  }

  Future<void> deleteQuestionBankQuestion(String bankQuestionId) async {
    final questionBank = await loadQuestionBank();
    final keptBank = questionBank.where((q) => q.id != bankQuestionId).toList();
    await saveQuestionBank(keptBank);

    final quizzes = await loadQuizzes();
    var hasQuizChanges = false;
    final now = DateTime.now();
    final updatedQuizzes = quizzes.map((quiz) {
      final keptQuestions = quiz.questions
          .where((question) => question.sourceBankQuestionId != bankQuestionId)
          .toList();
      if (keptQuestions.length == quiz.questions.length) {
        return quiz;
      }
      hasQuizChanges = true;
      return quiz.copyWith(
        questions: keptQuestions,
        version: quiz.version + 1,
        updatedAt: now,
      );
    }).toList();

    if (!hasQuizChanges) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _quizzesKey,
      jsonEncode(updatedQuizzes.map((q) => q.toJson()).toList()),
    );
  }

  Future<Map<String, List<GeneratedVariant>>> _loadAllVariants() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_variantsKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (quizId, value) => MapEntry(
        quizId,
        (value as List<dynamic>)
            .map((variant) => GeneratedVariant.fromJson(variant as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  Future<List<GeneratedVariant>> loadVariantsForQuiz(String quizId) async {
    final all = await _loadAllVariants();
    return all[quizId] ?? [];
  }

  Future<void> saveVariantsForQuiz(String quizId, List<GeneratedVariant> variants) async {
    final all = await _loadAllVariants();
    all[quizId] = variants;

    final prefs = await SharedPreferences.getInstance();
    final encoded = all.map(
      (key, value) => MapEntry(key, value.map((variant) => variant.toJson()).toList()),
    );
    await prefs.setString(_variantsKey, jsonEncode(encoded));
  }

  Future<void> deleteVariantsForQuiz(String quizId) async {
    final all = await _loadAllVariants();
    all.remove(quizId);

    final prefs = await SharedPreferences.getInstance();
    final encoded = all.map(
      (key, value) => MapEntry(key, value.map((variant) => variant.toJson()).toList()),
    );
    await prefs.setString(_variantsKey, jsonEncode(encoded));
  }
}
