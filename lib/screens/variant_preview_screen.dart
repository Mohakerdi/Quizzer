import 'package:flutter/material.dart';

import 'package:adv_basics/models/generated_variant.dart';

class VariantPreviewScreen extends StatelessWidget {
  const VariantPreviewScreen({
    super.key,
    required this.variant,
  });

  final GeneratedVariant variant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview ${variant.id}'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: variant.questions.length,
        itemBuilder: (context, index) {
          final question = variant.questions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${index + 1}. ${question.composedPrompt}'),
                  if (question.imageRef.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Image: ${question.imageRef}'),
                  ],
                  const SizedBox(height: 10),
                  ...question.options.map((option) {
                    final isCorrect = option.id == question.correctOptionId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.circle_outlined,
                            size: 18,
                            color: isCorrect ? Colors.green : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(option.composedText)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
