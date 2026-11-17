import 'package:flutter/material.dart';
import 'dcc/dcc_document_control_screen.dart';

class EqmsHomeScreen extends StatelessWidget {
  const EqmsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 30,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  // Logo
                  Container(
                    width: 150,
                    height: 150,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/full_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Welcome text
                  const Text(
                    'Welcome to eQMS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Electronic Quality Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 55),

                  // Application modules
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      int columns;

                      if (width >= 1050) {
                        columns = 5;
                      } else if (width >= 820) {
                        columns = 4;
                      } else if (width >= 590) {
                        columns = 3;
                      } else if (width >= 380) {
                        columns = 2;
                      } else {
                        columns = 1;
                      }

                      const double spacing = 20;

                      final cardWidth =
                      ((width - ((columns - 1) * spacing)) / columns)
                          .clamp(150.0, 190.0);

                      return Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [


                          SizedBox(
                            width: cardWidth,
                            child: _moduleCard(
                              context: context,
                              title: 'DCC',
                              subtitle: 'Document Control\nCenter',
                              icon: Icons.description_rounded,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/DCC',
                                );
                              },
                            ),
                          ),

                          SizedBox(
                            width: cardWidth,
                            child: _moduleCard(
                              context: context,
                              title: 'CCR',
                              subtitle: 'Customer Complaint',
                              icon: Icons.dashboard_customize_rounded,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/CCR',
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _moduleCard(
                              context: context,
                              title: 'NCR',
                              subtitle: 'Non-Conformance\nReport',
                              icon: Icons.warning_rounded,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/NCR',
                                );
                              },
                            ),
                          ),

                          SizedBox(
                            width: cardWidth,
                            child: _moduleCard(
                              context: context,
                              title: 'Audit',
                              subtitle: 'Audit Management',
                              icon: Icons.settings_suggest_rounded,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/AUDIT',
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),

                  // Footer
                  Text(
                    'eQMS  •  Quality Management Platform',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _moduleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 190,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE4E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF3FF),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    icon,
                    size: 29,
                    color: const Color(0xFF3155D9),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Color(0xFF7A8292),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}