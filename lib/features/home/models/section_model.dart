import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

class SectionModel extends Equatable {
  final String id;
  final String title;
  final String icon;
  final String to;

  const SectionModel( {required this.id,required this.to, required this.title, required this.icon, home});

  @override
  List<Object?> get props => [title, icon];

  // from Json
  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: validateString(json['id']),
      title: validateString(json['title']),
      icon: validateString(json['icon']),
      to: validateString(json['to']),
    );
  }

  // to Json
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'to': to,
      };
}
