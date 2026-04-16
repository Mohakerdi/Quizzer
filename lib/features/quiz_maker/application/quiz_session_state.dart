import 'package:equatable/equatable.dart';

import 'package:adv_basics/data/models/generated_variant.dart';
import 'package:adv_basics/data/models/quiz_model.dart';
import 'package:adv_basics/data/models/quiz_question.dart';

class QuizSessionState extends Equatable {
  const QuizSessionState({
    required this.quizzes,
    required this.selectedQuiz,
    required this.generatedVariants,
    required this.questionBank,
    required this.isLoading,
    this.message,
  });

  final List<QuizModel> quizzes;
  final QuizModel? selectedQuiz;
  final List<GeneratedVariant> generatedVariants;
  final List<QuizQuestion> questionBank;
  final bool isLoading;
  final String? message;

  const QuizSessionState.initial()
      : quizzes = const [],
        selectedQuiz = null,
        generatedVariants = const [],
        questionBank = const [],
        isLoading = true,
        message = null;

  QuizSessionState copyWith({
    List<QuizModel>? quizzes,
    QuizModel? selectedQuiz,
    bool clearSelectedQuiz = false,
    List<GeneratedVariant>? generatedVariants,
    List<QuizQuestion>? questionBank,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
  }) {
    return QuizSessionState(
      quizzes: quizzes ?? this.quizzes,
      selectedQuiz: clearSelectedQuiz ? null : (selectedQuiz ?? this.selectedQuiz),
      generatedVariants: generatedVariants ?? this.generatedVariants,
      questionBank: questionBank ?? this.questionBank,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [quizzes, selectedQuiz, generatedVariants, questionBank, isLoading, message];
}
