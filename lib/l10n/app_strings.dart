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
      case 'selectedQuiz':
        return ar ? 'المحدد حاليًا' : 'Currently selected';
      case 'invalidVariantsCount':
        return ar ? 'يرجى إدخال عدد صحيح للنماذج.' : 'Please enter a valid number of variants.';
      case 'quizzes':
        return ar ? 'الاختبارات' : 'Quizzes';
      case 'createQuizTooltip':
        return ar ? 'إنشاء اختبار' : 'Create quiz';
      case 'noQuizzesYet':
        return ar ? 'لا توجد اختبارات بعد.' : 'No quizzes yet.';
      case 'rename':
        return ar ? 'إعادة تسمية' : 'Rename';
      case 'duplicate':
        return ar ? 'نسخ' : 'Duplicate';
      case 'delete':
        return ar ? 'حذف' : 'Delete';
      case 'saveQuiz':
        return ar ? 'حفظ الاختبار' : 'Save Quiz';
      case 'validate':
        return ar ? 'تحقق' : 'Validate';
      case 'addQuestion':
        return ar ? 'إضافة سؤال' : 'Add Question';
      case 'generatedVariantsTitle':
        return ar ? 'النماذج المُولَّدة' : 'Generated Variants';
      case 'noVariantsYet':
        return ar ? 'لم يتم توليد نماذج بعد.' : 'No variants generated yet.';
      case 'preview':
        return ar ? 'معاينة' : 'Preview';
      case 'exportDocx':
        return ar ? 'تصدير DOCX' : 'Export DOCX';
      case 'docxExportDetails':
        return ar ? 'تفاصيل رأس مستند DOCX' : 'DOCX header details';
      case 'teacherName':
        return ar ? 'اسم المعلم' : 'Teacher name';
      case 'schoolName':
        return ar ? 'اسم المدرسة' : 'School name';
      case 'exportLanguage':
        return ar ? 'لغة التصدير' : 'Export language';
      case 'exportLanguageEnglish':
        return ar ? 'الإنجليزية' : 'English';
      case 'exportLanguageArabic':
        return ar ? 'العربية' : 'Arabic';
      case 'optionLabelStyle':
        return ar ? 'تنسيق ترقيم الخيارات' : 'Choice label style';
      case 'optionLabelStyleLatin':
        return ar ? 'A / B / C / D' : 'A / B / C / D';
      case 'optionLabelStyleArabic':
        return ar ? 'أ / ب / ج / د' : 'أ / ب / ج / د';
      case 'exportGoogleForms':
        return ar ? 'تصدير Google Forms' : 'Export Google Forms';
      case 'quizSaved':
        return ar ? 'تم حفظ الاختبار.' : 'Quiz saved.';
      case 'quizValid':
        return ar ? 'الاختبار صالح.' : 'Quiz is valid.';
      case 'validationErrors':
        return ar ? 'أخطاء التحقق' : 'Validation errors';
      case 'close':
        return ar ? 'إغلاق' : 'Close';
      case 'editImage':
        return ar ? 'تعديل الصورة' : 'Edit image';
      case 'applying':
        return ar ? 'جارٍ التطبيق...' : 'Applying...';
      case 'apply':
        return ar ? 'تطبيق' : 'Apply';
      case 'previewVariant':
        return ar ? 'معاينة النموذج' : 'Preview';
      case 'questionContent':
        return ar ? 'محتوى السؤال' : 'Question content';
      case 'questionContentHint':
        return ar ? 'اكتب نص السؤال والصيغ في مكان واحد' : 'Write question text and formulas in one place';
      case 'optionContent':
        return ar ? 'محتوى الخيار' : 'Option content';
      case 'optionContentHint':
        return ar ? 'اكتب النص أو الصيغة في مكان واحد' : 'Write text or formula in one place';
      case 'addOption':
        return ar ? 'إضافة خيار' : 'Add option';
      case 'editOption':
        return ar ? 'تعديل الخيار' : 'Edit option';
      case 'save':
        return ar ? 'حفظ' : 'Save';
      case 'addQuestionTitle':
        return ar ? 'إضافة سؤال' : 'Add question';
      case 'editQuestionTitle':
        return ar ? 'تعديل السؤال' : 'Edit question';
      case 'selectImageFromGallery':
        return ar ? 'اختر صورة من المعرض' : 'Select image from gallery';
      case 'crop':
        return ar ? 'قص' : 'Crop';
      case 'remove':
        return ar ? 'إزالة' : 'Remove';
      case 'options':
        return ar ? 'الخيارات' : 'Options';
      case 'emptyOption':
        return ar ? '(خيار فارغ)' : '(empty option)';
      case 'saveQuestion':
        return ar ? 'حفظ السؤال' : 'Save question';
      case 'unableToLoadImage':
        return ar ? 'تعذر تحميل الصورة المحددة.' : 'Unable to load selected image.';
      case 'mathKeyboardHelper':
        return ar ? 'لوحة مفاتيح رياضية شبيهة بـ GeoGebra مفعلة' : 'GeoGebra-like math keyboard enabled';
      case 'invalidMathExpression':
        return ar ? 'تعبير رياضي غير صالح' : 'Invalid math expression';
      case 'insertEquation':
        return ar ? 'إدراج معادلة' : 'Insert equation';
      case 'equationEditorTitle':
        return ar ? 'محرر المعادلة' : 'Equation editor';
      case 'equationFieldLabel':
        return ar ? 'المعادلة' : 'Equation';
      case 'equationFieldHint':
        return ar ? 'اكتب الصيغة الرياضية' : 'Type the math expression';
      case 'themeDark':
        return ar ? 'الوضع الداكن' : 'Dark mode';
      case 'themeLight':
        return ar ? 'الوضع الفاتح' : 'Light mode';
      case 'quizEditorTab':
        return ar ? 'محرر الاختبار' : 'Quiz Editor';
      case 'questionBankTab':
        return ar ? 'بنك الأسئلة' : 'Question Bank';
      case 'gradeLevel':
        return ar ? 'الصف' : 'Grade';
      case 'unitOfStudy':
        return ar ? 'الوحدة الدراسية' : 'Unit of study';
      case 'curriculum':
        return ar ? 'المنهج/المادة' : 'Curriculum';
      case 'questionBankEmpty':
        return ar ? 'لا توجد أسئلة في بنك الأسئلة بعد.' : 'No questions in the question bank yet.';
      case 'filterQuestions':
        return ar ? 'تصفية الأسئلة' : 'Filter questions';
      case 'selectAllVisible':
        return ar ? 'تحديد الكل (الظاهر)' : 'Select all visible';
      case 'clearSelection':
        return ar ? 'إلغاء التحديد' : 'Clear selection';
      case 'selectedCount':
        return ar ? 'تم تحديد' : 'Selected';
      case 'createQuizFromSelection':
        return ar ? 'إنشاء اختبار من المحدد' : 'Create quiz from selected';
      case 'newQuizFromBankTitle':
        return ar ? 'عنوان الاختبار الجديد' : 'New quiz title';
      case 'bankQuestionSource':
        return ar ? 'المصدر' : 'Source';
      default:
        return key;
    }
  }
}
