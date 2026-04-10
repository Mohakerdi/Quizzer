class FriendlyMathFormatter {
  const FriendlyMathFormatter._();

  static String format(String value) {
    var text = value.trim();
    if (text.isEmpty) {
      return text;
    }

    text = text.replaceAllMapped(RegExp(r'\\?\$\$(.+?)\\?\$\$', dotAll: true), (match) {
      return (match.group(1) ?? '').trim();
    });

    text = text
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\times', '×')
        .replaceAll(r'\div', '÷')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠')
        .replaceAll('<=', '≤')
        .replaceAll('>=', '≥')
        .replaceAll('!=', '≠');

    text = text.replaceAllMapped(RegExp(r'sqrt\s*\(([^()]*)\)', caseSensitive: false), (m) {
      return '√(${m.group(1)})';
    });
    text = text.replaceAllMapped(RegExp(r'\\sqrt\{([^{}]*)\}'), (m) {
      return '√(${m.group(1)})';
    });

    final fracLatex = RegExp(r'\\(?:cfrac|dfrac|tfrac|frac)\{([^{}]+)\}\{([^{}]+)\}');
    while (fracLatex.hasMatch(text)) {
      text = text.replaceAllMapped(fracLatex, (m) => '(${m.group(1)})/(${m.group(2)})');
    }

    text = text.replaceAllMapped(
      RegExp(r'\\(arcsin|arccos|arctan|sin|cos|tan|cot|sec|csc|log|ln|lim|min|max)\b'),
      (m) => m.group(1)!,
    );

    final caretSuperscript = RegExp(r'([^\s])\^([0-9+-]+)');
    text = text.replaceAllMapped(
      caretSuperscript,
      (m) => '${m.group(1)}${_toSuperscript(m.group(2) ?? '')}',
    );

    return text;
  }

  static String _toSuperscript(String value) {
    const map = <String, String>{
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '+': '⁺',
      '-': '⁻',
    };
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final mapped = map[char];
      if (mapped == null) {
        return '^$value';
      }
      buffer.write(mapped);
    }
    return buffer.toString();
  }
}
