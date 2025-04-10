import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

class HomeCardModel extends Equatable {
  final int? id;
  final String? title;
  final String? description;
  final String? imageUrl;

  const HomeCardModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.imageUrl,
      home});

  @override
  List<Object?> get props => [title, description, imageUrl];

  // from Json
  factory HomeCardModel.fromJson(Map<String, dynamic> json) {
    return HomeCardModel(
      id: json['id'],
      title: validateString(json['title']),
      description: validateString(json['description']),
      imageUrl: validateString(json['image']),
    );
  }

  // to Json
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'image': imageUrl,
      };
}
