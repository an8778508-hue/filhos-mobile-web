import 'package:escola/core/utils/date_time_utils.dart';
import 'package:escola/core/utils/valid_data.dart';

class AlarmModel {
  final String id;
  final DateTime? date;

  AlarmModel({
    required this.id,
    required this.date,
  });

  //from json
  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    final date = json['date'];
    final time = json['time'];
    return AlarmModel(
      id: validateString(json['id'].toString()),
      date: (validString(date) && validString(time)) ? parseDateTime('$date $time') : null,
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
    };
  }
}
