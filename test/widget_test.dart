import 'package:flutter_test/flutter_test.dart';

import 'package:adv_basics/app.dart';

void main() {
  testWidgets('renders quiz maker shell', (tester) async {
    await tester.pumpWidget(const QuizMakerApp());
    await tester.pumpAndSettle();

    expect(find.text('Quizzer Maker'), findsOneWidget);
  });
}
