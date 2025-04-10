import 'package:equatable/equatable.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/diary/models/category_menu_item.dart';
import 'package:escola/features/diary/models/child_model.dart';

class ChildMenuModel extends Equatable {
  final ChildModel childModel;
  final List<Menu> menus;

  const ChildMenuModel({required this.childModel, required this.menus});

  @override
  List<Object?> get props => [childModel, menus];

  // toJson
  Map<String, dynamic> toJson() => {
        'child': childModel.toJson(),
        'menus': menus.map((e) => e.toJson()),
      };

  // from Json
  factory ChildMenuModel.fromJson(Map<String, dynamic> json) {
    return ChildMenuModel(
      childModel: ChildModel.fromJson(json['child']??{}),
      menus: json['menus'] == null
          ? []
          : List<Menu>.from(json['menus'].map((x) => Menu.fromJson(x??{}))),
    );
  }
}
