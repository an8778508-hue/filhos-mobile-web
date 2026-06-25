import 'package:flutter/material.dart';

/// Teacher form to log an incident / accident report for a child.
class LogIncidentScreen extends StatefulWidget {
  /// The child this incident is being logged for.
  final int childId;

  /// Optional display name for the child (header only).
  final String? childName;

  /// Called with the validated form data when the user taps Submit.
  final void Function({
    required int childId,
    required String incidentType,
    required String severity,
    required String description,
    required String actionTaken,
    String? occurredAt,
  })? onSubmit;

  const LogIncidentScreen({
    super.key,
    required this.childId,
    this.childName,
    this.onSubmit,
  });

  @override
  State<LogIncidentScreen> createState() => _LogIncidentScreenState();
}

class _LogIncidentScreenState extends State<LogIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _actionTakenController = TextEditingController();

  static const _incidentTypes = ['accident', 'illness', 'behaviour', 'other'];
  static const _severities = ['minor', 'moderate', 'serious'];

  String? _selectedType;
  String? _selectedSeverity;
  DateTime? _occurredAt;

  @override
  void dispose() {
    _descriptionController.dispose();
    _actionTakenController.dispose();
    super.dispose();
  }

  Future<void> _pickOccurredAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt ?? now),
    );
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  String? _formatOccurredAt() {
    final dt = _occurredAt;
    if (dt == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit?.call(
        childId: widget.childId,
        incidentType: _selectedType!,
        severity: _selectedSeverity!,
        description: _descriptionController.text.trim(),
        actionTaken: _actionTakenController.text.trim(),
        occurredAt: _formatOccurredAt(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Incident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.childName != null) ...[
                Text(widget.childName!, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Incident type'),
                items: _incidentTypes
                    .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                validator: (v) => v == null ? 'Please select an incident type' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: _severities
                    .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSeverity = v),
                validator: (v) => v == null ? 'Please select a severity' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _actionTakenController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Action taken'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Action taken is required' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickOccurredAt,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Occurred at'),
                  child: Text(
                    _occurredAt == null ? 'Select date & time' : _formatOccurredAt()!,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
