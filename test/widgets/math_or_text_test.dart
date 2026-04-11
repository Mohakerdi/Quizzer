import 'package:adv_basics/widgets/math_or_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders arabic mixed math-like text as Text in RTL', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathOrText(r'ما الحل إذا علمت أن \sqrt[3]{x} = \frac{4}{2}'),
        ),
      ),
    );

    expect(find.byType(Text), findsOneWidget);
    expect(find.byType(Math), findsNothing);
  });
}
