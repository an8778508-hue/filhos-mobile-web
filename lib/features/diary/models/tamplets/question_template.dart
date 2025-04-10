import 'package:equatable/equatable.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';

class QuestionTemplate extends Equatable {
  final int id, categoryId;
  final String? title;
  final QuestionType? type;
  final List<SelectItem>? selectItems;
  final int? defaultSelect;
  // final bool? isMultiSelect;
  // final String? checkOnValue;
  // final String? checkOffValue;

  const QuestionTemplate(
      {required this.title,
      required this.type,
      required this.id,
      required this.categoryId,
      required this.selectItems,
      required this.defaultSelect,
      // required this.isMultiSelect,
      // required this.checkOnValue,
      // required this.checkOffValue
      });

  @override
  List<Object?> get props =>
      [id, categoryId, title, type, selectItems, defaultSelect, ];

  // from Json
  factory QuestionTemplate.fromJson(Map<String, dynamic> json, int categoryId) {
    return QuestionTemplate(
        id: json['id'],
        categoryId: categoryId,
        title: json['title'],
        type: json['type'].toString().toQuestionType(),
        selectItems: json['selectChoices'] == null
            ? null
            : List<SelectItem>.from(json['selectChoices']?.map((x) => SelectItem.fromJson(x))),
        defaultSelect: json['default_select'],
        // isMultiSelect: json['multi_select'] == true,
        // checkOnValue: json['check_values'] == null ? null : json['check_values']?['on'],
        // checkOffValue: json['check_values'] == null ? null : json['check_values']?['off']
    );
  }
}
