import 'package:adv_basics/core/widgets/math_or_text.dart';
import 'package:flutter/material.dart';
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

    expect(find.text('ما الحل إذا علمت أن ³√(x) = (4)/(2)'), findsOneWidget);
  });
}
