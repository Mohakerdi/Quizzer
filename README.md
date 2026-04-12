# Quizzer Maker

Quizzer is now a **quiz creation app** focused on building teacher-friendly multiple-choice quizzes, generating shuffled variants, and exporting DOCX files.

## Current workflow

1. **Quiz List**
   - Create, rename, duplicate, and delete quizzes.
2. **Create / Edit Quiz**
    - Add/edit/remove/reorder questions.
    - Add/edit/remove options.
    - Mark the correct option by stable option ID.
    - Unified single content field for question/option writing (text + formulas together).
    - Select question images from gallery and crop before saving.
    - Add questions to a persistent Question Bank.
3. **Question Bank**
   - Question bank is stored independently from quizzes.
   - Delete quizzes without losing bank questions.
   - Delete bank questions without changing already copied quiz questions.
4. **Math-friendly authoring**
   - GeoGebra-like math keyboard input (`math_keyboard` package).
   - Live LaTeX preview for math expressions.
   - Supports richer function/operator entry than simple symbol chips.
5. **Generate Variants**
   - Generate multiple shuffled versions.
   - Question and option order are shuffled while preserving correct answers.
6. **Preview**
   - Preview generated variants before exporting.
7. **Export DOCX**
    - Export question paper DOCX (table-based layout).
    - Export solutions DOCX using the same layout, with correct options highlighted.
    - Math text is exported in formula-style plain math output (not raw LaTeX markers).

## Persistence

- Quizzes and generated variants are persisted locally via `shared_preferences`.
- Question Bank is persisted independently from quizzes via `shared_preferences`.
- Deleting a question from Question Bank does not remove existing copied questions from quizzes.

## Architecture notes

- The app follows an MVVM-style structure:
  - **View**: `lib/screens/*`, `lib/widgets/*`, and `lib/app.dart`
  - **ViewModel**: `lib/view_models/quiz_maker_cubit.dart`, `lib/view_models/quiz_maker_state.dart`
  - **Model**: `lib/models/*`
  - **Data/Services**: `lib/services/*`
- Recent refactor highlights:
  - Extracted home UI sections into focused widgets for cleaner View composition.
  - Reduced unnecessary root rebuilds by selecting only locale/theme for `MaterialApp`.
  - Added selective rebuild rules in the home state consumer to avoid rebuilds on message-only updates.

## Notes / MVP limitations

- The question paper DOCX is table-based and print-friendly, but exact visual parity with the provided reference images may need further styling refinements.
- Images are stored as local/URL references for authoring and previews; DOCX export embeds image binaries directly when available, with a path-text fallback only if loading fails.
- Solutions layout is implemented as a structured answer-key table and can be adjusted once final template details are confirmed.
- Arabic locale/RTL is supported in UI and DOCX text flow for Arabic content detection.

## Development

```bash
flutter pub get
flutter analyze
flutter test
```
