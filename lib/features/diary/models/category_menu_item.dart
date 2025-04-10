import 'package:equatable/equatable.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';

class Menu extends Equatable {
  final String? title;
  final List<String?>? items;

  const Menu({required this.title, required this.items});

  @override
  List<Object?> get props => [title, items];

  // toJson
  Map<String, dynamic> toJson() => {
        'title': title,
        'items': items,
      };

  // from Json
  factory Menu.fromJson(Map<String, dynamic> json) {
    print('Menu.fromJson ${json}');
    return Menu(
      title: json['title'],
      items: json['items'] == null
          ? []
          : List<String>.from(json['items'].map((x) {
            // todo language
              final currentLanguageKey = UserBloc.get.state.language;
              // final translatedItem = x['title'][currentLanguageKey];

              return ((x?['title']??'')  );
            })),
    );
  }
}
