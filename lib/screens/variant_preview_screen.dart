import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:adv_basics/l10n/app_strings.dart';
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
        title: Text('${AppStrings.tr(context, 'previewVariant')} ${variant.id}'),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildPreviewImage(question.imageRef),
                    ),
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

  Widget _buildPreviewImage(String imageRef) {
    final dataBytes = _decodeDataImageBytes(imageRef);
    if (dataBytes != null) {
      return Image.memory(
        dataBytes,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, __, ___) => Text(AppStrings.tr(context, 'unableToLoadImage')),
      );
    }
    if (imageRef.startsWith('http')) {
      return Image.network(
        imageRef,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, __, ___) => Text(AppStrings.tr(context, 'unableToLoadImage')),
      );
    }
    return Image.file(
      File(imageRef),
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, __, ___) => Text(AppStrings.tr(context, 'unableToLoadImage')),
    );
  }

  Uint8List? _decodeDataImageBytes(String value) {
    if (!value.startsWith('data:image/')) {
      return null;
    }
    final comma = value.indexOf(',');
    if (comma < 0 || comma + 1 >= value.length) {
      return null;
    }
    try {
      return Uint8List.fromList(base64Decode(value.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }
}
