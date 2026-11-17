import 'package:flutter/material.dart';

class AuditCategoryCard extends StatelessWidget {
  final String categoryName;
  final int completed;
  final int total;
  final VoidCallback onTap;

  const AuditCategoryCard({
    super.key,
    required this.categoryName,
    required this.completed,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final complete =
        total > 0 &&
            completed == total;

    return Card(
      elevation: 0,
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE4E8F0),
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding:
          const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color: complete
                      ? Colors.green
                      .withValues(
                    alpha: .10,
                  )
                      : Colors.blue
                      .withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  complete
                      ? Icons.check_circle_outline
                      : Icons.assignment_outlined,
                  color: complete
                      ? Colors.green
                      : const Color(
                    0xFF3155C6,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      '$completed / $total completed',
                      style:
                      const TextStyle(
                        color:
                        Color(0xFF707784),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                complete
                    ? Icons.check_circle
                    : Icons.chevron_right,
                color: complete
                    ? Colors.green
                    : const Color(
                  0xFF7A8290,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}