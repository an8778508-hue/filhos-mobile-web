import 'package:escola/features/attendance/bloc/attendance_bloc.dart';
import 'package:escola/features/attendance/bloc/attendance_state.dart';
import 'package:escola/features/attendance/model/attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Teacher screen to mark a class roster's attendance for a given date.
///
/// Provides a class selector, a date picker, a per-child present/late/absent
/// toggle, a "mark all present" shortcut and a submit (bulk) button.
///
/// The [bloc] is injected so it can be mocked in widget tests.
class TeacherAttendanceScreen extends StatefulWidget {
  final AttendanceBloc bloc;

  /// Classes the teacher can pick from: `{id, name}`.
  final List<Map<String, dynamic>> classes;

  const TeacherAttendanceScreen({
    super.key,
    required this.bloc,
    this.classes = const [],
  });

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  late int? _classId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _classId = widget.classes.isNotEmpty ? widget.classes.first['id'] as int : null;
    _date = DateTime.now();
    _reload();
  }

  String get _dateString =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  void _reload() {
    if (_classId != null) {
      widget.bloc.load(classId: _classId!, date: _dateString);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: Column(
          children: [
            _buildControls(),
            const Divider(height: 1),
            Expanded(child: _buildRoster()),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (widget.classes.isNotEmpty)
            Expanded(
              child: DropdownButton<int>(
                key: const Key('class_selector'),
                isExpanded: true,
                value: _classId,
                items: widget.classes
                    .map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name']?.toString() ?? 'Class'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _classId = value);
                  _reload();
                },
              ),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
            key: const Key('date_picker'),
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_dateString),
          ),
        ],
      ),
    );
  }

  Widget _buildRoster() {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final rs = state.rosterState;

        if (rs.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (rs.data.isEmpty) {
          return const Center(child: Text('No children in this class'));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: rs.data.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final child = rs.data[index];
                  return _AttendanceRow(
                    child: child,
                    status: state.statusFor(child.childId),
                    onChanged: (status) => widget.bloc.setStatus(child.childId, status),
                  );
                },
              ),
            ),
            _buildActions(state),
          ],
        );
      },
    );
  }

  Widget _buildActions(AttendanceState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('mark_all_present'),
                onPressed: () => widget.bloc.markAllPresent(),
                child: const Text('Mark all present'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: const Key('submit_attendance'),
                onPressed: state.submitting ? null : () => widget.bloc.submit(),
                child: state.submitting
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceModel child;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  const _AttendanceRow({
    required this.child,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(child.childName.isEmpty ? 'Child' : child.childName)),
          ToggleButtons(
            key: Key('toggle_${child.childId}'),
            isSelected: [
              status == AttendanceStatus.present,
              status == AttendanceStatus.late,
              status == AttendanceStatus.absent,
            ],
            onPressed: (index) {
              const order = [AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.absent];
              onChanged(order[index]);
            },
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Present')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Late')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Absent')),
            ],
          ),
        ],
      ),
    );
  }
}
