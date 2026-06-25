import 'package:escola/features/allergies/bloc/allergy_bloc.dart';
import 'package:escola/features/allergies/bloc/allergy_state.dart';
import 'package:escola/features/allergies/model/allergy_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Allergy section for the child profile.
///
/// Shows the child's allergy records and, when any exist, a RED badge to flag
/// the child as having allergies. When [canEdit] is true (nursery admins) the
/// add / edit / delete controls are shown; teachers and parents see a
/// read-only list.
class AllergySection extends StatelessWidget {
  final AllergyBloc bloc;
  final bool canEdit;

  const AllergySection({
    super.key,
    required this.bloc,
    this.canEdit = false,
  });

  Color _severityColor(String severity) {
    switch (severity) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<AllergyBloc, AllergyState>(
        builder: (context, state) {
          final allergies = state.data;
          final hasAllergies = state.hasAllergies;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Allergies',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (hasAllergies) ...[
                    const SizedBox(width: 8),
                    Container(
                      key: const Key('allergy_badge'),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Text(
                        '${allergies.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (canEdit)
                    IconButton(
                      key: const Key('add_allergy'),
                      icon: const Icon(Icons.add),
                      onPressed: () => _showForm(context),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.allergiesState.loading)
                const Center(child: CircularProgressIndicator())
              else if (!hasAllergies)
                const Text('No allergies recorded')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allergies.length,
                  itemBuilder: (context, index) {
                    final item = allergies[index];
                    return ListTile(
                      key: Key('allergy_row_${item.id}'),
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _severityColor(item.severity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(item.allergen),
                      subtitle: Text(
                        [
                          'Severity: ${item.severity}',
                          if (item.reactionDescription != null) 'Reaction: ${item.reactionDescription}',
                          if (item.actionToTake != null) 'Action: ${item.actionToTake}',
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: canEdit
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: Key('edit_allergy_${item.id}'),
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showForm(context, existing: item),
                                ),
                                IconButton(
                                  key: Key('delete_allergy_${item.id}'),
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => bloc.remove(item.id),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, {AllergyModel? existing}) {
    final allergenController = TextEditingController(text: existing?.allergen ?? '');
    final reactionController = TextEditingController(text: existing?.reactionDescription ?? '');
    final actionController = TextEditingController(text: existing?.actionToTake ?? '');
    String severity = existing?.severity ?? 'mild';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Allergy' : 'Edit Allergy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('allergen_field'),
                  controller: allergenController,
                  decoration: const InputDecoration(labelText: 'Allergen'),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('severity_field'),
                  value: severity,
                  items: const [
                    DropdownMenuItem(value: 'mild', child: Text('Mild')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'severe', child: Text('Severe')),
                  ],
                  onChanged: (value) => severity = value ?? 'mild',
                ),
                TextField(
                  key: const Key('reaction_field'),
                  controller: reactionController,
                  decoration: const InputDecoration(labelText: 'Reaction description'),
                ),
                TextField(
                  key: const Key('action_field'),
                  controller: actionController,
                  decoration: const InputDecoration(labelText: 'Action to take'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('save_allergy'),
              onPressed: () {
                if (existing == null) {
                  bloc.create(
                    allergen: allergenController.text,
                    severity: severity,
                    reactionDescription: reactionController.text,
                    actionToTake: actionController.text,
                  );
                } else {
                  bloc.update(
                    id: existing.id,
                    allergen: allergenController.text,
                    severity: severity,
                    reactionDescription: reactionController.text,
                    actionToTake: actionController.text,
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
