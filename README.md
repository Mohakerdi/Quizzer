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
3. **Math-friendly authoring**
   - GeoGebra-like math keyboard input (`math_keyboard` package).
   - Live LaTeX preview for math expressions.
   - Supports richer function/operator entry than simple symbol chips.
4. **Generate Variants**
   - Generate multiple shuffled versions.
   - Question and option order are shuffled while preserving correct answers.
5. **Preview**
   - Preview generated variants before exporting.
6. **Export DOCX**
    - Export question paper DOCX (table-based layout).
    - Export solutions DOCX using the same layout, with correct options highlighted.
    - Math text is exported in formula-style plain math output (not raw LaTeX markers).

## Persistence

- Quizzes and generated variants are persisted locally via `shared_preferences`.

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
