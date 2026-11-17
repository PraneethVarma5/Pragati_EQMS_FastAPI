import 'package:flutter/material.dart';

import '../../../services/dcc/dcc_document_request_service.dart';
import 'user_document_requests_screen.dart';
import '../../../services/dcc/dcc_notification_service.dart';
import '../../../services/dcc/dcc_session.dart';

class RequestDocumentScreen extends StatefulWidget {
  const RequestDocumentScreen({super.key});

  @override
  State<RequestDocumentScreen> createState() =>
      _RequestDocumentScreenState();
}

class _RequestDocumentScreenState
    extends State<RequestDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _documentNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _documentNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = DccSession.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DCC session not found.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await DccDocumentRequestService.createRequest(
        documentName: _documentNameController.text,
        userName: user.name,
        userEmail: user.email,
        description: _descriptionController.text,
      );

      // Nobody was being told a request had come in — DCC only
      // ever found out if they happened to check the requests
      // list. Mirrors the "New Document -> Notification" flow.
      await DccNotificationService.notifyAllDcc(
        title: 'New Document Request',
        message: '${user.name} requested '
            '"${_documentNameController.text.trim()}".',
        type: 'DOCUMENT_REQUEST_SUBMITTED',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document request sent to DCC.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = DccSession.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Request New Document',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Request a New Document',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Tell DCC what document you need and why — "
                    "they'll prepare it and notify you when it's "
                    "ready to upload.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE4E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requested By',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF172033),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Automatically filled from your account.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _infoRow('Name', user?.name ?? '-'),
                        _infoRow('Email', user?.email ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE4E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF172033),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'What document do you need, and why?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _documentNameController,
                          decoration: InputDecoration(
                            labelText: 'Document Name',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter document name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          minLines: 5,
                          maxLines: 8,
                          maxLength: 500,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText:
                                'Explain what the document should '
                                'cover and why you need it...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter description';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const UserDocumentRequestsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.list_alt_rounded,
                        ),
                        label: const Text(
                          'View Requests',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                          const Color(0xFF3155D9),
                          side: const BorderSide(
                            color: Color(0xFF3155D9),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      ElevatedButton.icon(
                        onPressed:
                        _saving ? null : _submitRequest,
                        icon: _saving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.send_rounded,
                        ),
                        label: Text(
                          _saving
                              ? 'Sending...'
                              : 'Send Request to DCC',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF3155D9),
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172033),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
