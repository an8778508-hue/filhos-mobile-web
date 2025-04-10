import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';


class MultiSelectModel extends Equatable {
  final String id;
  final String title;

  const MultiSelectModel({
    required this.id,
    required this.title,
  });

  factory MultiSelectModel.fromJson(Map<String, dynamic> json) => MultiSelectModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };

  @override
  List<Object?> get props => [
        id,
        title,
      ];
}
