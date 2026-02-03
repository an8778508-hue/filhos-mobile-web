import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';

class ImagesQuestion extends Question {
  final List<dynamic>? images;
  final MainCategory? mainCategory;

  const ImagesQuestion({
    required super.id,
    required String? label,
    super.subtitle,
    required this.images,
    this.mainCategory,
  }) : super(
          type: QuestionType.image,
          // mainCategory: mainCategory,
          title: label,
          value: images,
        );

  @override
  List<Object?> get props => [id, type, title, subtitle, images];

  // to Json
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'image',
        'label': title,
        'value': images,
      };

  // copy With
  ImagesQuestion copyWith({
    int? id,
    String? label,
    String? subtitle,
    List<dynamic>? images,
  }) {
    return ImagesQuestion(
      id: id ?? this.id,
      label: label ?? title,
      subtitle: subtitle ?? this.subtitle,
      images: images ?? this.images,
    );
  }
}
