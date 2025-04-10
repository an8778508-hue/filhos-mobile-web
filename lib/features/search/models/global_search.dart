import 'package:equatable/equatable.dart';
import 'package:escola/features/diary/models/school_item.dart';

class GlobalSearchResult extends Equatable {
  final List<SchoolItem> teachers;
  final List<SchoolItem> parents;
  final List<SchoolItem> children;
  final List<SchoolItem> levels;

  const GlobalSearchResult(
      {required this.teachers,
      required this.parents,
      required this.children,
      required this.levels});

  @override
  List<Object?> get props => [teachers, parents, children, levels];
}
