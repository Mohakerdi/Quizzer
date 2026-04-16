import 'dart:convert';

import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class QuizLocalDataSource {
  Future<List<QuizModel>> loadQuizzes();
  Future<void> saveQuizzes(List<QuizModel> quizzes);

  Future<List<QuizQuestion>> loadQuestionBank();
  Future<void> saveQuestionBank(List<QuizQuestion> questions);

  Future<Map<String, List<GeneratedVariant>>> loadAllVariants();
  Future<void> saveAllVariants(Map<String, List<GeneratedVariant>> variantsByQuizId);
}

class SharedPreferencesQuizLocalDataSource implements QuizLocalDataSource {
  static const _quizzesKey = 'quizzer_quizzes_v1';
  static const _variantsKey = 'quizzer_variants_v1';
  static const _questionBankKey = 'quizzer_question_bank_v1';

  const SharedPreferencesQuizLocalDataSource();

  @override
  Future<List<QuizModel>> loadQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quizzesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => QuizModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveQuizzes(List<QuizModel> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _quizzesKey,
      jsonEncode(quizzes.map((q) => q.toJson()).toList()),
    );
  }

  @override
  Future<List<QuizQuestion>> loadQuestionBank() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_questionBankKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveQuestionBank(List<QuizQuestion> questions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _questionBankKey,
      jsonEncode(questions.map((q) => q.toJson()).toList()),
    );
  }

  @override
  Future<Map<String, List<GeneratedVariant>>> loadAllVariants() async {
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

  @override
  Future<void> saveAllVariants(Map<String, List<GeneratedVariant>> variantsByQuizId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = variantsByQuizId.map(
      (key, value) => MapEntry(key, value.map((variant) => variant.toJson()).toList()),
    );
    await prefs.setString(_variantsKey, jsonEncode(encoded));
  }
}
