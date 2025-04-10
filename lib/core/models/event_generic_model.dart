import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/utils/valid_data.dart';

class EventGenericModel {
  final DateTime? date;
  final List<EventModel> events;

  EventGenericModel({
    required this.date,
    required this.events,
  });

  //from json
  factory EventGenericModel.fromJson(Map<String, dynamic> json) {
    return EventGenericModel(
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      events:
          json['events'] != null ? (json['events'] as List).map((event) => EventModel.fromJson(event)).toList() : [],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'events': events.map((event) => event.toJson()).toList(),
    };
  }
}
