class LatexDetection {
  const LatexDetection._();

  static const Set<String> supportedCommands = {
    'frac',
    'dfrac',
    'tfrac',
    'cfrac',
    'sqrt',
    'sum',
    'int',
    'pi',
    'theta',
    'times',
    'div',
    'leq',
    'geq',
    'neq',
    'alpha',
    'beta',
    'gamma',
    'delta',
    'lambda',
    'mu',
    'sigma',
    'omega',
    'sin',
    'cos',
    'tan',
    'cot',
    'sec',
    'csc',
    'log',
    'ln',
    'lim',
    'cdot',
    'pm',
    'mp',
    'left',
    'right',
    'begin',
    'end',
  };

  static final RegExp latexCommandPattern = RegExp(
    '\\\\(${supportedCommands.join('|')})\\b',
  );

  static bool looksLikeLatexMath(String value) {
    return latexCommandPattern.hasMatch(value);
  }

  static bool hasMathDelimiters(String value) {
    return RegExp(r'\$\$').hasMatch(value);
  }

  static String wrapLatexLikeTextWithInlineDelimiters(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (hasMathDelimiters(normalized)) {
      return normalized;
    }
    if (looksLikeLatexMath(normalized)) {
      return '${r'$$'}$normalized${r'$$'}';
    }
    return normalized;
  }
}
