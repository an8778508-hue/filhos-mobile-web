import 'package:escola/features/milestones/bloc/milestone_bloc.dart';
import 'package:escola/features/milestones/bloc/milestone_state.dart';
import 'package:escola/features/milestones/model/milestone_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Exact amber overdue prompt shown for overdue milestones.
const String kMilestoneOverdueText = 'يستاهل تذكره مع متخصص';

/// Developmental milestone tracking screen with four domain tabs.
///
/// Teachers (bloc.asTeacher == true) can toggle a milestone reached; parents
/// see a read-only progress view. Overdue, not-yet-reached milestones show an
/// amber prompt to see a specialist.
///
/// The [bloc] is injected so it can be mocked in widget tests.
class MilestonesScreen extends StatefulWidget {
  final MilestoneBloc bloc;
  final String title;

  const MilestonesScreen({
    super.key,
    required this.bloc,
    this.title = 'Milestones',
  });

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  static const _domains = MilestoneBloc.domains;

  static const Map<String, String> _domainLabels = {
    'social': 'Social',
    'language': 'Language',
    'cognitive': 'Cognitive',
    'motor': 'Motor',
  };

  @override
  void initState() {
    super.initState();
    widget.bloc.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: DefaultTabController(
        length: _domains.length,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                for (final d in _domains) Tab(text: _domainLabels[d] ?? d),
              ],
            ),
          ),
          body: BlocBuilder<MilestoneBloc, MilestoneState>(
            builder: (context, state) {
              if (state.milestonesState.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              return TabBarView(
                children: [
                  for (final d in _domains)
                    _DomainTab(
                      milestones: state.byDomain(d),
                      asTeacher: widget.bloc.asTeacher,
                      onToggle: (m) => widget.bloc.mark(m.id),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DomainTab extends StatelessWidget {
  final List<MilestoneModel> milestones;
  final bool asTeacher;
  final ValueChanged<MilestoneModel> onToggle;

  const _DomainTab({
    required this.milestones,
    required this.asTeacher,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const Center(child: Text('No milestones'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: milestones.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = milestones[index];
        return _MilestoneTile(
          milestone: m,
          asTeacher: asTeacher,
          onToggle: () => onToggle(m),
        );
      },
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final MilestoneModel milestone;
  final bool asTeacher;
  final VoidCallback onToggle;

  const _MilestoneTile({
    required this.milestone,
    required this.asTeacher,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleChildren = <Widget>[
      Text('${milestone.ageBandMin}-${milestone.ageBandMax} months'),
    ];

    if (milestone.overdue && !milestone.reached) {
      subtitleChildren.add(
        const Text(
          kMilestoneOverdueText,
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final trailing = asTeacher
        ? Checkbox(
            value: milestone.reached,
            // Already-reached milestones cannot be un-reached from here.
            onChanged: milestone.reached ? null : (_) => onToggle(),
          )
        : Icon(
            milestone.reached ? Icons.check_circle : Icons.radio_button_unchecked,
            color: milestone.reached ? Colors.green : Colors.grey,
          );

    return ListTile(
      title: Text(milestone.descriptionAr, textDirection: TextDirection.rtl),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtitleChildren,
      ),
      trailing: trailing,
    );
  }
}
