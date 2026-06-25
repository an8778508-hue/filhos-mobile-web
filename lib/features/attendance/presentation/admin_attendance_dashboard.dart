import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/attendance/bloc/attendance_today_bloc.dart';
import 'package:escola/features/attendance/model/attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Admin dashboard card showing today's attendance counts.
/// Tapping it opens the full list of today's attendance rows.
///
/// The [bloc] is injected so it can be mocked in widget tests.
class AdminAttendanceDashboard extends StatefulWidget {
  final AttendanceTodayBloc bloc;

  const AdminAttendanceDashboard({super.key, required this.bloc});

  @override
  State<AdminAttendanceDashboard> createState() => _AdminAttendanceDashboardState();
}

class _AdminAttendanceDashboardState extends State<AdminAttendanceDashboard> {
  @override
  void initState() {
    super.initState();
    widget.bloc.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocBuilder<AttendanceTodayBloc, GenericDataState<AttendanceTodayModel>>(
        builder: (context, state) {
          if (state.loading) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final today = state.data ?? const AttendanceTodayModel();

          return Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TodayAttendanceList(records: today.records),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Attendance",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Counter(key: const Key('count_present'), label: 'Present', value: today.present, color: Colors.green),
                        _Counter(key: const Key('count_late'), label: 'Late', value: today.late, color: Colors.orange),
                        _Counter(key: const Key('count_absent'), label: 'Absent', value: today.absent, color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Counter({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label),
      ],
    );
  }
}

class _TodayAttendanceList extends StatelessWidget {
  final List<AttendanceModel> records;

  const _TodayAttendanceList({required this.records});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Attendance")),
      body: records.isEmpty
          ? const Center(child: Text('No attendance recorded today'))
          : ListView.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = records[index];
                return ListTile(
                  title: Text(r.childName.isEmpty ? 'Child' : r.childName),
                  trailing: Text(attendanceStatusToString(r.status)),
                );
              },
            ),
    );
  }
}
