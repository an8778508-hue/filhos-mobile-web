import 'package:equatable/equatable.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/professor.dart';
import 'package:escola/features/diary/models/question_category.dart';

class Activity extends Equatable {
  // final int id;
  final ChildModel? childModel;
  final List<QuestionCategory> questionCategories;
  final Professor? professor;
  final DateTime? fromDate, toDate, date;
  final MainCategory? mainCategory;

  const Activity({
    // required this.id,
    required this.childModel,
    required this.questionCategories,
    this.professor,
    this.mainCategory,
    required this.fromDate,
    required this.toDate,
    required this.date,
  });

  @override
  List<Object?> get props => [childModel, questionCategories, professor, date];

  // from Json
  factory Activity.fromJson(Map<String, dynamic> json) {
    // print('Activity.fromJson ${json['answers'][0]}');
    return Activity(
      // id: json['id'],
      childModel: json['child'] != null ? ChildModel.fromJson(json['child']) : null,
      professor: json['teacher'] != null ? Professor.fromJson(json['teacher']) : null,
      questionCategories: List<QuestionCategory>.from(json['answers'].map((x) => QuestionCategory.fromJson(x))),
      fromDate: json['fromDate'] != null ? DateTime.parse(json['fromDate']) : null,
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
      mainCategory: json['type'] == null ? null : MainCategory.fromJson(json['type']),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }

  // to Json
  Map<String, dynamic> toJson() => {
        // 'id': id,
        'child': childModel?.toJson(),
        'teacher': professor?.toJson(),
        'category': mainCategory?.toJson(),
        'questionCategories': questionCategories.map((x) => x.toJson()).toList(),
        'fromDate': fromDate?.toIso8601String(),
        'toDate': toDate?.toIso8601String(),
        'date': date?.toIso8601String(),
      };
}
