import 'package:equatable/equatable.dart';
import 'package:escola/core/models/gender.dart';

class Professor extends Equatable {
  final int? id;
  final String? name, avatar;
  final Gender? gender;

  const Professor({
    required this.name,
    required this.id,
    required this.avatar,
    required this.gender,
  });

  @override
  List<Object?> get props => [name, avatar];

  // fromJson
  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
        name: json['name'],
        id: json['id'],
        avatar: json['avatar'],
        gender: json['gender'].toString().toGender());
  }

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
        'avatar': avatar,
        'gender': gender.toStringType()
      };
}
