import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';

class StartAuditScreen extends StatefulWidget {
const StartAuditScreen({super.key});

@override
State<StartAuditScreen> createState() => _StartAuditScreenState();
}

class _StartAuditScreenState extends State<StartAuditScreen> {
final _formKey = GlobalKey<FormState>();

final TextEditingController _auditDateController = TextEditingController();
final TextEditingController _vendorController = TextEditingController();
final TextEditingController _siteController = TextEditingController();
final TextEditingController _lobController = TextEditingController();
final TextEditingController _programController = TextEditingController();
final TextEditingController _lineController = TextEditingController();
final TextEditingController _apnController = TextEditingController();
final TextEditingController _auditorNameController = TextEditingController();
final TextEditingController _auditorEmailController = TextEditingController();
final TextEditingController _totalHoursController = TextEditingController();

List<Map<String, dynamic>> _auditTypes = [];
String? _selectedTypeId;

DateTime _selectedAuditDate = DateTime.now();

bool _loadingTypes = true;
bool _saving = false;

@override
void initState() {
super.initState();

_auditDateController.text = _formatDate(_selectedAuditDate);

_loadAuditTypes();
}

@override
void dispose() {
_auditDateController.dispose();
_vendorController.dispose();
_siteController.dispose();
_lobController.dispose();
_programController.dispose();
_lineController.dispose();
_apnController.dispose();
_auditorNameController.dispose();
_auditorEmailController.dispose();
_totalHoursController.dispose();

super.dispose();
}

String _formatDate(DateTime date) {
final month = date.month.toString().padLeft(2, '0');
final day = date.day.toString().padLeft(2, '0');

return '${date.year}-$month-$day';
}

Future<void> _loadAuditTypes() async {
try {
final types = await SupabaseService.getActiveAuditTypes();

if (!mounted) return;

setState(() {
_auditTypes = types;
_loadingTypes = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
_loadingTypes = false;
});

_showError('Unable to load Audit Types: $e');
}
}

Future<void> _selectAuditDate() async {
final selected = await showDatePicker(
context: context,
initialDate: _selectedAuditDate,
firstDate: DateTime(2000),
lastDate: DateTime(2100),
);

if (selected == null) return;

setState(() {
_selectedAuditDate = selected;
_auditDateController.text = _formatDate(selected);
});
}

Future<void> _saveAudit() async {
if (!_formKey.currentState!.validate()) {
return;
}

if (_selectedTypeId == null) {
_showError('Please select an Audit Type.');
return;
}

final totalHours = double.tryParse(
_totalHoursController.text.trim(),
);

if (totalHours == null || totalHours <= 0) {
_showError('Total Audit Hours must be greater than 0.');
return;
}

setState(() {
_saving = true;
});

try {
final audit = await SupabaseService.createAudit(
typeId: _selectedTypeId!,
auditDate: _formatDate(_selectedAuditDate),
vendor: _vendorController.text.trim(),
site: _siteController.text.trim(),
lob: _lobController.text.trim(),
program: _programController.text.trim().isEmpty
? null
    : _programController.text.trim(),
line: _lineController.text.trim().isEmpty
? null
    : _lineController.text.trim(),
apn: _apnController.text.trim().isEmpty
? null
    : _apnController.text.trim(),
auditorName: _auditorNameController.text.trim(),
auditorEmail: _auditorEmailController.text.trim().isEmpty
? null
    : _auditorEmailController.text.trim(),
totalAuditHours: totalHours,
);

if (!mounted) return;

final auditId = audit['audit_id']?.toString();

if (auditId == null || auditId.isEmpty) {
throw Exception('Audit was created but no Audit ID was returned.');
}

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Audit created successfully.'),
),
);

Navigator.pushReplacementNamed(
context,
'/AUDIT/categories',
arguments: auditId,
);
} catch (e) {
if (!mounted) return;

_showError('Unable to create audit: $e');
} finally {
if (mounted) {
setState(() {
_saving = false;
});
}
}
}

void _showError(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: Colors.red.shade700,
),
);
}

Widget _buildTextField({
required String label,
required TextEditingController controller,
bool required = true,
TextInputType? keyboardType,
int maxLines = 1,
bool readOnly = false,
VoidCallback? onTap,
}) {
return TextFormField(
controller: controller,
keyboardType: keyboardType,
maxLines: maxLines,
readOnly: readOnly,
onTap: onTap,
decoration: InputDecoration(
labelText: required ? '$label *' : label,
border: const OutlineInputBorder(),
suffixIcon: onTap == null
? null
    : const Icon(Icons.calendar_today_outlined),
),
validator: (value) {
if (!required) {
return null;
}

if (value == null || value.trim().isEmpty) {
return '$label is required.';
}

return null;
},
);
}

Widget _buildSection({
required String title,
required IconData icon,
required List<Widget> children,
}) {
return Card(
margin: const EdgeInsets.only(bottom: 20),
elevation: 1,
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(icon),
const SizedBox(width: 10),
Text(
title,
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
const SizedBox(height: 20),
...children,
],
),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Start New Audit'),
),
body: SafeArea(
child: _loadingTypes
? const Center(
child: CircularProgressIndicator(),
)
    : Form(
key: _formKey,
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 1000,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Text(
'Audit Details',
style: Theme.of(context)
    .textTheme
    .headlineSmall
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
'Enter the information required to start this audit.',
style: Theme.of(context).textTheme.bodyMedium,
),
const SizedBox(height: 24),

_buildSection(
title: 'Audit Information',
icon: Icons.fact_check_outlined,
children: [
DropdownButtonFormField<String>(
value: _selectedTypeId,
decoration: const InputDecoration(
labelText: 'Audit Type *',
border: OutlineInputBorder(),
),
items: _auditTypes.map((type) {
final id =
type['type_id']?.toString() ?? '';
final name =
type['audit_type']?.toString() ?? '';

return DropdownMenuItem<String>(
value: id,
child: Text(name),
);
}).toList(),
onChanged: (value) {
setState(() {
_selectedTypeId = value;
});
},
validator: (value) {
if (value == null || value.isEmpty) {
return 'Audit Type is required.';
}

return null;
},
),
const SizedBox(height: 16),
_buildTextField(
label: 'Audit Date',
controller: _auditDateController,
readOnly: true,
onTap: _selectAuditDate,
),
const SizedBox(height: 16),
_buildTextField(
label: 'Total Audit Hours',
controller: _totalHoursController,
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
),
],
),

_buildSection(
title: 'Organization / Scope',
icon: Icons.business_outlined,
children: [
_buildTextField(
label: 'Vendor',
controller: _vendorController,
),
const SizedBox(height: 16),
_buildTextField(
label: 'Site',
controller: _siteController,
),
const SizedBox(height: 16),
_buildTextField(
label: 'LOB',
controller: _lobController,
),
const SizedBox(height: 16),
_buildTextField(
label: 'Program',
controller: _programController,
required: false,
),
const SizedBox(height: 16),
_buildTextField(
label: 'Line',
controller: _lineController,
required: false,
),
const SizedBox(height: 16),
_buildTextField(
label: 'APN',
controller: _apnController,
required: false,
),
],
),

_buildSection(
title: 'Auditor Information',
icon: Icons.person_outline,
children: [
_buildTextField(
label: 'Auditor Name',
controller: _auditorNameController,
),
const SizedBox(height: 16),
_buildTextField(
label: 'Auditor Email',
controller: _auditorEmailController,
required: false,
keyboardType: TextInputType.emailAddress,
),
],
),

const SizedBox(height: 4),

SizedBox(
height: 52,
child: ElevatedButton.icon(
onPressed: _saving ? null : _saveAudit,
icon: _saving
? const SizedBox(
height: 20,
width: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(Icons.play_arrow),
label: Text(
_saving
? 'Creating Audit...'
    : 'Start Audit',
),
),
),
],
),
),
),
),
),
),
);
}
}
