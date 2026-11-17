import 'package:flutter/material.dart';

import '../../models/audit/audit_type_model.dart';
import '../../services/audit/audit_service_new.dart';
import 'audit_categories_screen_new.dart';

class CreateAuditScreenNew extends StatefulWidget {
  const CreateAuditScreenNew({
    super.key,
  });

  @override
  State<CreateAuditScreenNew> createState() =>
      _CreateAuditScreenNewState();
}

class _CreateAuditScreenNewState
    extends State<CreateAuditScreenNew> {
  final AuditServiceNew _service =
  AuditServiceNew();

  final _formKey = GlobalKey<FormState>();

  final _milController = TextEditingController();
  final _vendorController = TextEditingController();
  final _siteController = TextEditingController();
  final _lobController = TextEditingController();
  final _programController = TextEditingController();
  final _lineController = TextEditingController();
  final _apnController = TextEditingController();

  List<AuditTypeModelNew> _auditTypes = [];

  AuditTypeModelNew? _selectedType;

  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadAuditTypes();
  }

  @override
  void dispose() {
    _milController.dispose();
    _vendorController.dispose();
    _siteController.dispose();
    _lobController.dispose();
    _programController.dispose();
    _lineController.dispose();
    _apnController.dispose();

    super.dispose();
  }

  Future<void> _loadAuditTypes() async {
    try {
      final types =
      await _service.getAuditTypes();

      if (!mounted) {
        return;
      }

      setState(() {
        _auditTypes = types;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load audit types: $e',
          ),
        ),
      );
    }
  }

  Future<void> _createAudit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select an audit type.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      final audit =
      await _service.createAudit(
        milNumber:
        _milController.text.trim(),
        auditType:
        _selectedType!.auditType,
        vendor:
        _vendorController.text.trim(),
        site:
        _siteController.text.trim(),
        lob:
        _lobController.text.trim(),
        program:
        _programController.text.trim(),
        line:
        _lineController.text.trim(),
        apn:
        _apnController.text.trim(),
        auditor: '',
        auditDate:
        DateTime.now().toIso8601String(),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NewAuditCategoriesScreen(
                audit: audit,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create audit: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Audit',
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeDropdown(),
            const SizedBox(height: 16),

            _field(
              controller: _milController,
              label: 'MIL Number',
              requiredField: true,
            ),
            _field(
              controller: _vendorController,
              label: 'Vendor',
            ),
            _field(
              controller: _siteController,
              label: 'Site',
            ),
            _field(
              controller: _lobController,
              label: 'LOB',
            ),
            _field(
              controller: _programController,
              label: 'Program',
            ),
            _field(
              controller: _lineController,
              label: 'Line',
            ),
            _field(
              controller: _apnController,
              label: 'APN',
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed:
                _creating
                    ? null
                    : _createAudit,
                child: _creating
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Start Audit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<
        AuditTypeModelNew>(
      value: _selectedType,
      decoration:
      const InputDecoration(
        labelText: 'Audit Type',
        border: OutlineInputBorder(),
      ),
      items: _auditTypes
          .map(
            (type) =>
            DropdownMenuItem<
                AuditTypeModelNew>(
              value: type,
              child: Text(
                type.auditType,
              ),
            ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedType = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Select audit type';
        }

        return null;
      },
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool requiredField = false,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration:
        InputDecoration(
          labelText: label,
          border:
          const OutlineInputBorder(),
        ),
        validator: requiredField
            ? (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return '$label is required';
          }

          return null;
        }
            : null,
      ),
    );
  }
}