import 'package:escola/features/immunisations/bloc/immunisation_bloc.dart';
import 'package:escola/features/immunisations/bloc/immunisation_state.dart';
import 'package:escola/features/immunisations/model/immunisation_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immunisation section for the child profile.
///
/// Lists the child's immunisation records. Records whose next dose is due
/// within the next 30 days (`isDueSoon`) are highlighted in AMBER. When
/// [canEdit] is true (nursery admins) the add / edit / delete controls are
/// shown; teachers and parents see a read-only list.
class ImmunisationSection extends StatelessWidget {
  final ImmunisationBloc bloc;
  final bool canEdit;

  const ImmunisationSection({
    super.key,
    required this.bloc,
    this.canEdit = false,
  });

  static const Color dueSoonColor = Colors.amber;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ImmunisationBloc, ImmunisationState>(
        builder: (context, state) {
          final immunisations = state.data;
          final hasImmunisations = state.hasImmunisations;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Immunisations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  if (canEdit)
                    IconButton(
                      key: const Key('add_immunisation'),
                      icon: const Icon(Icons.add),
                      onPressed: () => _showForm(context),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.immunisationsState.loading)
                const Center(child: CircularProgressIndicator())
              else if (!hasImmunisations)
                const Text('No immunisations recorded')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: immunisations.length,
                  itemBuilder: (context, index) {
                    final item = immunisations[index];
                    final dueSoon = item.isDueSoon;

                    return Container(
                      key: dueSoon ? Key('immunisation_due_soon_${item.id}') : null,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: dueSoon
                          ? BoxDecoration(
                              color: dueSoonColor.withOpacity(0.25),
                              border: Border.all(color: dueSoonColor),
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: ListTile(
                        key: Key('immunisation_row_${item.id}'),
                        title: Text(item.vaccineName),
                        subtitle: Text(
                          [
                            if (item.dateGiven != null) 'Given: ${item.dateGiven}',
                            if (item.nextDueDate != null) 'Next due: ${item.nextDueDate}',
                            if (item.notes != null) 'Notes: ${item.notes}',
                          ].join('\n'),
                        ),
                        isThreeLine: true,
                        trailing: _buildTrailing(context, item, dueSoon),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context, ImmunisationModel item, bool dueSoon) {
    final children = <Widget>[];

    if (dueSoon) {
      children.add(
        Icon(
          Icons.warning_amber_rounded,
          key: Key('immunisation_due_badge_${item.id}'),
          color: dueSoonColor,
        ),
      );
    }

    if (canEdit) {
      children.addAll([
        IconButton(
          key: Key('edit_immunisation_${item.id}'),
          icon: const Icon(Icons.edit),
          onPressed: () => _showForm(context, existing: item),
        ),
        IconButton(
          key: Key('delete_immunisation_${item.id}'),
          icon: const Icon(Icons.delete),
          onPressed: () => bloc.remove(item.id),
        ),
      ]);
    }

    if (children.isEmpty) {
      return null;
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  void _showForm(BuildContext context, {ImmunisationModel? existing}) {
    final vaccineController = TextEditingController(text: existing?.vaccineName ?? '');
    final dateGivenController = TextEditingController(text: existing?.dateGiven ?? '');
    final nextDueController = TextEditingController(text: existing?.nextDueDate ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Immunisation' : 'Edit Immunisation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('vaccine_name_field'),
                  controller: vaccineController,
                  decoration: const InputDecoration(labelText: 'Vaccine name'),
                ),
                TextField(
                  key: const Key('date_given_field'),
                  controller: dateGivenController,
                  decoration: const InputDecoration(labelText: 'Date given (YYYY-MM-DD)'),
                ),
                TextField(
                  key: const Key('next_due_date_field'),
                  controller: nextDueController,
                  decoration: const InputDecoration(labelText: 'Next due date (YYYY-MM-DD)'),
                ),
                TextField(
                  key: const Key('notes_field'),
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
              key: const Key('save_immunisation'),
              onPressed: () {
                final nextDue = nextDueController.text.trim().isEmpty ? null : nextDueController.text.trim();
                final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
                if (existing == null) {
                  bloc.create(
                    vaccineName: vaccineController.text,
                    dateGiven: dateGivenController.text,
                    nextDueDate: nextDue,
                    notes: notes,
                  );
                } else {
                  bloc.update(
                    id: existing.id,
                    vaccineName: vaccineController.text,
                    dateGiven: dateGivenController.text,
                    nextDueDate: nextDue,
                    notes: notes,
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
