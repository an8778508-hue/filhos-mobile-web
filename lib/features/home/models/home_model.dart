import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/child_model.dart';

class HomeModel {
  final List<EventModel> events;
  final List<ChildModel> children;
  // final List<SectionModel> sections;

  HomeModel({
    required this.events,
    required this.children,
    // required this.sections,
  });

  //from json
  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      events: validateDataList(json['events'], (json) => EventModel.fromJson(json)),
      children: validateDataList(json['childs'], (json) => ChildModel.fromJson(json)),
      // sections: validateDataList(
      //     json['sections'], (json) => SectionModel.fromJson(json)),
    );
  }

  //to json
  Map<String, dynamic> toJson() {
    return {
      'events': events,
      'children': children.map((e) => e.toJson()),
      // 'sections': sections.map((e) => e.toJson()),
    };
  }
}
