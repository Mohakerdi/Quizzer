class LatexDetection {
  const LatexDetection._();

  static final RegExp latexCommandPattern = RegExp(
    r'\\(frac|dfrac|tfrac|cfrac|sqrt|sum|int|pi|theta|times|div|leq|geq|neq|alpha|beta|gamma|delta|lambda|mu|sigma|omega|sin|cos|tan|cot|sec|csc|log|ln|lim|cdot|pm|mp|left|right|begin|end)\b',
  );

  static bool looksLikeLatexMath(String value) {
    return latexCommandPattern.hasMatch(value);
  }
}
