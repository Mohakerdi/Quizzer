import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings._();

  static bool isArabic(BuildContext context) => Localizations.localeOf(context).languageCode == 'ar';

  static String tr(BuildContext context, String key) {
    final ar = isArabic(context);
    switch (key) {
      case 'appTitle':
        return ar ? 'منشئ الاختبارات' : 'Quizzer Maker';
      case 'newQuiz':
        return ar ? 'اختبار جديد' : 'New Quiz';
      case 'createQuiz':
        return ar ? 'إنشاء اختبار' : 'Create Quiz';
      case 'quizTitle':
        return ar ? 'عنوان الاختبار' : 'Quiz title';
      case 'renameQuiz':
        return ar ? 'إعادة تسمية الاختبار' : 'Rename Quiz';
      case 'generateVariants':
        return ar ? 'توليد نماذج' : 'Generate Variants';
      case 'howManyVersions':
        return ar ? 'كم عدد النماذج؟' : 'How many versions?';
      case 'cancel':
        return ar ? 'إلغاء' : 'Cancel';
      case 'ok':
        return ar ? 'موافق' : 'OK';
      case 'selectQuiz':
        return ar ? 'أنشئ أو اختر اختبارًا للبدء.' : 'Create or select a quiz to start.';
      case 'invalidVariantsCount':
        return ar ? 'يرجى إدخال عدد صحيح للنماذج.' : 'Please enter a valid number of variants.';
      default:
        return key;
    }
  }
}
