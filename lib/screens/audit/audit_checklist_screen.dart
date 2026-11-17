import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';

class AuditChecklistScreen extends StatefulWidget {
final String auditId;
final String categoryId;

const AuditChecklistScreen({
super.key,
required this.auditId,
required this.categoryId,
});

@override
State<AuditChecklistScreen> createState() =>
_AuditChecklistScreenState();
}

class _AuditChecklistScreenState extends State<AuditChecklistScreen> {
List<Map<String, dynamic>> _questions = [];

final Map<String, String?> _answers = {};
final Map<String, TextEditingController> _descriptionControllers = {};
final Map<String, String?> _defectTypes = {};

String? _categoryName;

bool _loading = true;
bool _saving = false;

@override
void initState() {
super.initState();
_loadChecklist();
}

@override
void dispose() {
for (final controller in _descriptionControllers.values) {
controller.dispose();
}

super.dispose();
}

Future<void> _loadChecklist() async {
try {
final category = await SupabaseService.getAuditCategoryById(
widget.categoryId,
);

final questions = await SupabaseService.getAuditQuestions(
widget.categoryId,
);

final existingAnswers =
await SupabaseService.getAuditChecklistAnswers(
auditId: widget.auditId,
questionIds: questions
    .map(
(question) =>
question['question_id']?.toString(),
)
    .whereType<String>()
    .toList(),
);

final existingByQuestion = <String, Map<String, dynamic>>{};

for (final answer in existingAnswers) {
final questionId = answer['question_id']?.toString();

if (questionId != null && questionId.isNotEmpty) {
existingByQuestion[questionId] = answer;
}
}

for (final question in questions) {
final questionId =
question['question_id']?.toString();

if (questionId == null || questionId.isEmpty) {
continue;
}

final existing = existingByQuestion[questionId];

_answers[questionId] =
existing?['answer']?.toString();

_defectTypes[questionId] =
existing?['defect_type']?.toString();

_descriptionControllers[questionId] =
TextEditingController(
text: existing?['description']?.toString() ?? '',
);
}

if (!mounted) return;

setState(() {
_categoryName =
category?['category_name']?.toString();
_questions = questions;
_loading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
_loading = false;
});

_showError('Unable to load checklist: $e');
}
}

void _selectAnswer(
String questionId,
String answer,
) {
setState(() {
_answers[questionId] = answer;

if (answer == 'Yes') {
// Defect Type must disappear completely for Yes.
_defectTypes[questionId] = null;
}
});
}

bool _validateChecklist() {
for (final question in _questions) {
final questionId =
question['question_id']?.toString();

if (questionId == null || questionId.isEmpty) {
continue;
}

final answer = _answers[questionId];

if (answer == null || answer.isEmpty) {
_showError(
'Please answer every question before saving.',
);
return false;
}

if (answer == 'No') {
final description =
_descriptionControllers[questionId]?.text.trim() ?? '';

if (description.isEmpty) {
_showError(
'Description is required for every No answer.',
);
return false;
}

final defectType = _defectTypes[questionId];

if (defectType == null || defectType.isEmpty) {
_showError(
'Defect Type is required for every No answer.',
);
return false;
}
}
}

return true;
}

Future<void> _saveChecklist() async {
if (_saving) return;

if (!_validateChecklist()) {
return;
}

setState(() {
_saving = true;
});

try {
for (final question in _questions) {
final questionId =
question['question_id']?.toString();

if (questionId == null || questionId.isEmpty) {
continue;
}

final answer = _answers[questionId];

final description =
_descriptionControllers[questionId]?.text.trim() ?? '';

final defectType =
answer == 'No'
? _defectTypes[questionId]
    : null;

await SupabaseService.saveAuditChecklistAnswer(
auditId: widget.auditId,
questionId: questionId,
answer: answer!,
description: description.isEmpty
? null
    : description,
defectType: defectType,
);
}

await SupabaseService.completeAuditCategory(
auditId: widget.auditId,
categoryId: widget.categoryId,
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Checklist saved successfully.'),
),
);

Navigator.pop(context);
} catch (e) {
if (!mounted) return;

_showError('Unable to save checklist: $e');
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

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
_categoryName == null || _categoryName!.isEmpty
? 'Audit Checklist'
    : _categoryName!,
),
actions: [
IconButton(
tooltip: 'Save Checklist',
onPressed: _saving ? null : _saveChecklist,
icon: _saving
? const SizedBox(
height: 20,
width: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(Icons.save_outlined),
),
],
),
body: SafeArea(
child: _loading
? const Center(
child: CircularProgressIndicator(),
)
    : _buildBody(),
),
);
}

Widget _buildBody() {
if (_questions.isEmpty) {
return const Center(
child: Padding(
padding: EdgeInsets.all(24),
child: Text(
'No active questions are configured for this category.',
textAlign: TextAlign.center,
),
),
);
}

return SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 1300,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
_buildHeader(),
const SizedBox(height: 20),
...List.generate(
_questions.length,
(index) {
return _buildQuestionCard(
question: _questions[index],
index: index,
);
},
),
const SizedBox(height: 16),
_buildSaveButton(),
],
),
),
),
);
}

Widget _buildHeader() {
return Card(
elevation: 1,
child: Padding(
padding: const EdgeInsets.all(20),
child: Row(
children: [
const Icon(Icons.fact_check_outlined),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
_categoryName ?? 'Audit Checklist',
style: Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'${_questions.length} question${_questions.length == 1 ? '' : 's'}',
),
],
),
),
],
),
),
);
}

Widget _buildQuestionCard({
required Map<String, dynamic> question,
required int index,
}) {
final questionId =
question['question_id']?.toString() ?? '';

final questionNumber =
question['question_number']?.toString() ??
'${index + 1}';

final questionText =
question['question']?.toString() ?? '';

final questionDescription =
question['description']?.toString() ?? '';

final selectedAnswer = _answers[questionId];

final descriptionController =
_descriptionControllers[questionId];

return Card(
margin: const EdgeInsets.only(bottom: 16),
elevation: 1,
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// --------------------------------------------------
// QUESTION
// --------------------------------------------------
Text(
'$questionNumber. $questionText',
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(
fontWeight: FontWeight.w600,
),
),

if (questionDescription.isNotEmpty) ...[
const SizedBox(height: 8),
Text(
questionDescription,
style: Theme.of(context)
    .textTheme
    .bodyMedium,
),
],

const SizedBox(height: 18),

// --------------------------------------------------
// ONE-LINE RESPONSE ROW
// --------------------------------------------------
_buildResponseRow(
questionId: questionId,
selectedAnswer: selectedAnswer,
descriptionController:
descriptionController,
),
],
),
),
);
}

Widget _buildResponseRow({
required String questionId,
required String? selectedAnswer,
required TextEditingController? descriptionController,
}) {
return Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
// YES
_buildAnswerOption(
questionId: questionId,
label: 'Yes',
value: 'Yes',
selectedAnswer: selectedAnswer,
),

const SizedBox(width: 16),

// NO
_buildAnswerOption(
questionId: questionId,
label: 'No',
value: 'No',
selectedAnswer: selectedAnswer,
),

const SizedBox(width: 20),

// DESCRIPTION
Expanded(
flex: 3,
child: TextField(
controller: descriptionController,
minLines: 1,
maxLines: 2,
decoration: const InputDecoration(
labelText: 'Description',
hintText: 'Enter description',
border: OutlineInputBorder(),
isDense: true,
),
),
),

// DEFECT TYPE
if (selectedAnswer == 'No') ...[
const SizedBox(width: 20),
Expanded(
flex: 2,
child: _buildDefectTypeDropdown(
questionId,
),
),
],
],
);
}

Widget _buildAnswerOption({
required String questionId,
required String label,
required String value,
required String? selectedAnswer,
}) {
return InkWell(
borderRadius: BorderRadius.circular(8),
onTap: () {
_selectAnswer(
questionId,
value,
);
},
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 4,
vertical: 8,
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Radio<String>(
value: value,
groupValue: selectedAnswer,
onChanged: (newValue) {
if (newValue == null) return;

_selectAnswer(
questionId,
newValue,
);
},
),
Text(
label,
style: const TextStyle(
fontWeight: FontWeight.w500,
),
),
],
),
),
);
}

Widget _buildDefectTypeDropdown(
String questionId,
) {
return DropdownButtonFormField<String>(
value: _defectTypes[questionId],
decoration: const InputDecoration(
labelText: 'Defect Type',
border: OutlineInputBorder(),
isDense: true,
),
items: const [
DropdownMenuItem(
value: 'Critical',
child: Text('Critical'),
),
DropdownMenuItem(
value: 'Major',
child: Text('Major'),
),
DropdownMenuItem(
value: 'Minor',
child: Text('Minor'),
),
],
onChanged: (value) {
setState(() {
_defectTypes[questionId] = value;
});
},
);
}

Widget _buildSaveButton() {
return SizedBox(
height: 52,
child: ElevatedButton.icon(
onPressed: _saving ? null : _saveChecklist,
icon: _saving
? const SizedBox(
height: 20,
width: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(Icons.save_outlined),
label: Text(
_saving
? 'Saving Checklist...'
    : 'Save & Complete Category',
),
),
);
}
}