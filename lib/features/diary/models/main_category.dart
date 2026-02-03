import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

class MainCategory extends Equatable {
  final int? id;
  final String? name, image, type, value, statusType;

  static String foodType = 'food';

  const MainCategory({
    required this.name,
    required this.image,
    required this.id,
    required this.statusType,
    required this.type,
    required this.value,
  });

  @override
  List<Object?> get props => [name, image, type, value];

  // from Json
  factory MainCategory.fromJson(Map<String, dynamic> json) {

    return MainCategory(
      statusType: json['attendance_type'],
      id: json['id'],
      name: json['name'],
      image: json['image'],
      type: json['type'],
      value: json['attendance_type'],
    );
  }

  // to Json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (validString(type)) 'type': type,
      if (validString(value)) 'attendance_type': value,
    };
  }

  // copyWith
  MainCategory copyWith({
    String? name,
    String? image,
    String? menuIcon,
    String? type,
    String? statusType,
    String? value,
    int? id,
  }) {
    return MainCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      type: type ?? this.type,
      statusType: statusType ?? this.statusType,
      value: value ?? this.value,
    );
  }
}
