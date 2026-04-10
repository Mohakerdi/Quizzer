import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:adv_basics/models/generated_variant.dart';
import 'package:adv_basics/models/quiz_model.dart';

class QuizMakerState extends Equatable {
  const QuizMakerState({
    required this.quizzes,
    required this.selectedQuiz,
    required this.generatedVariants,
    required this.isLoading,
    required this.locale,
    required this.themeMode,
    this.message,
  });

  final List<QuizModel> quizzes;
  final QuizModel? selectedQuiz;
  final List<GeneratedVariant> generatedVariants;
  final bool isLoading;
  final Locale locale;
  final ThemeMode themeMode;
  final String? message;

  const QuizMakerState.initial()
      : quizzes = const [],
        selectedQuiz = null,
        generatedVariants = const [],
        isLoading = true,
        locale = const Locale('en'),
        themeMode = ThemeMode.light,
        message = null;

  QuizMakerState copyWith({
    List<QuizModel>? quizzes,
    QuizModel? selectedQuiz,
    bool clearSelectedQuiz = false,
    List<GeneratedVariant>? generatedVariants,
    bool? isLoading,
    Locale? locale,
    ThemeMode? themeMode,
    String? message,
    bool clearMessage = false,
  }) {
    return QuizMakerState(
      quizzes: quizzes ?? this.quizzes,
      selectedQuiz: clearSelectedQuiz ? null : (selectedQuiz ?? this.selectedQuiz),
      generatedVariants: generatedVariants ?? this.generatedVariants,
      isLoading: isLoading ?? this.isLoading,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [quizzes, selectedQuiz, generatedVariants, isLoading, locale, themeMode, message];
}
