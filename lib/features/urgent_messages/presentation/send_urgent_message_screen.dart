import 'package:flutter/material.dart';

class SendUrgentMessageScreen extends StatefulWidget {
  /// List of parents to choose from. Each entry: {id:int, name:String}.
  final List<Map<String, dynamic>> parents;

  /// Called with the validated form data when the user taps Send.
  final void Function({
    required int parentId,
    required String title,
    required String description,
  })? onSend;

  const SendUrgentMessageScreen({
    super.key,
    required this.parents,
    this.onSend,
  });

  @override
  State<SendUrgentMessageScreen> createState() => _SendUrgentMessageScreenState();
}

class _SendUrgentMessageScreenState extends State<SendUrgentMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedParentId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSend?.call(
        parentId: _selectedParentId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Urgent Message')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedParentId,
                decoration: const InputDecoration(labelText: 'Parent'),
                items: widget.parents
                    .map(
                      (p) => DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text('${p['name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedParentId = v),
                validator: (v) => v == null ? 'Please select a parent' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (v.trim().length > 100) {
                    return 'Title must be at most 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (v.trim().length > 500) {
                    return 'Description must be at most 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
