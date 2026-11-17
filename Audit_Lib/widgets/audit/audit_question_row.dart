import 'package:flutter/material.dart';

import '../../models/audit/audit_question_model_new.dart';

class AuditQuestionRow extends StatelessWidget {
  final AuditQuestionModel question;

  final String? answer;
  final String? description;
  final String? findingCategory;

  final List<String> answerOptions;
  final List<String> findingCategories;

  final ValueChanged<String?> onAnswerChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String?> onFindingCategoryChanged;

  const AuditQuestionRow({
    super.key,
    required this.question,
    required this.answer,
    required this.description,
    required this.findingCategory,
    required this.answerOptions,
    required this.findingCategories,
    required this.onAnswerChanged,
    required this.onDescriptionChanged,
    required this.onFindingCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE3E7EE),
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              '${question.questionNumber}. ${question.question}',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w700,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value:
                    answerOptions.contains(
                      answer,
                    )
                        ? answer
                        : null,
                    decoration:
                    _decoration(
                      'Answer',
                    ),
                    items:
                    answerOptions
                        .map(
                          (value) {
                        return DropdownMenuItem<
                            String>(
                          value: value,
                          child:
                          Text(value),
                        );
                      },
                    ).toList(),
                    onChanged:
                    onAnswerChanged,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  flex: 4,
                  child: TextFormField(
                    initialValue:
                    description,
                    minLines: 1,
                    maxLines: 4,
                    onChanged:
                    onDescriptionChanged,
                    decoration:
                    _decoration(
                      'Description',
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value:
                    findingCategories
                        .contains(
                      findingCategory,
                    )
                        ? findingCategory
                        : null,
                    decoration:
                    _decoration(
                      'Defect Type',
                    ),
                    items:
                    findingCategories
                        .map(
                          (value) {
                        return DropdownMenuItem<
                            String>(
                          value: value,
                          child:
                          Text(value),
                        );
                      },
                    ).toList(),
                    onChanged:
                    onFindingCategoryChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(
      String label,
      ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor:
      const Color(0xFFF8F9FB),
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
        borderSide:
        const BorderSide(
          color: Color(0xFFE0E3E8),
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
        borderSide:
        const BorderSide(
          color: Color(0xFFE0E3E8),
        ),
      ),
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
    );
  }
}