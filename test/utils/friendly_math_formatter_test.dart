import 'package:adv_basics/utils/friendly_math_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes cfrac style fractions', () {
    expect(
      FriendlyMathFormatter.format(r'\cfrac{\sin(x)}{x}'),
      '(sin(x))/(x)',
    );
  });

  test('strips leading backslash from math functions for export-safe text', () {
    expect(
      FriendlyMathFormatter.format(r'\sin(x) + \cos(x)'),
      'sin(x) + cos(x)',
    );
  });

  test('preserves symbolic latex commands outside function whitelist', () {
    expect(
      FriendlyMathFormatter.format(r'\alpha + \beta'),
      r'\alpha + \beta',
    );
  });

  test('normalizes indexed latex roots', () {
    expect(
      FriendlyMathFormatter.format(r'\sqrt[3]{x} + \sqrt[12]{y}'),
      '³√(x) + ¹²√(y)',
    );
  });

  test('normalizes indexed roots without leading backslash', () {
    expect(
      FriendlyMathFormatter.format(r'sqrt[3]{x}'),
      '³√(x)',
    );
  });
}
