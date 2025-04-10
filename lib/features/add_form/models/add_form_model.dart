import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/models/attachments_model.dart';
import 'package:escola/features/add_form/models/multiselect_model.dart';
import 'package:escola/features/add_form/models/number_model.dart';
import 'package:escola/features/add_form/models/period_of_time_model.dart';
import 'package:escola/features/add_form/models/upload_image_model.dart';
import 'package:escola/features/add_form/models/attendants_selection_model.dart';
import 'package:escola/features/add_form/models/comments_model.dart';
import 'package:escola/features/add_form/models/date_picker_model.dart';
import 'package:escola/features/add_form/models/dropdown_model.dart';
import 'package:escola/features/add_form/models/segmented_control_model.dart';

import 'collection_model.dart';
import 'counter_model.dart';
import 'create_meeting_button_model.dart';
import 'group_model.dart';
import 'rich_text_model.dart';
import 'text_area_model.dart';
import 'text_model.dart';
import 'time_picker_model.dart';

class AddFormFormModel extends Equatable {
  final List<FormModel> fields;

  const AddFormFormModel({
    required this.fields,
  });

  factory AddFormFormModel.fromJson(Map<String, dynamic> json) => AddFormFormModel(
        fields: validateDataList(json['data'], (e) => FormModel.fromJson(e)),
      );

  Map<String, dynamic> toJson() => {
        'data': fields.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        fields,
      ];
}

enum FormType {
  counter,
  dropdown,
  multiselect,
  segmented,
  periodOfTime,
  collection,
  group,
  attendantsSelection,
  uploadImage,
  attachment,
  comments,
  text,
  number,
  textArea,
  richText,
  datePicker,
  timePicker,
  createMeetingButton,
  unimplemented,
}

abstract class FormModel extends Equatable {
  final FormType type;
  final String title;
  final String id;
  final bool required;
  final FormDependencyModel? dependency;

  const FormModel({
    required this.id,
    required this.type,
    required this.title,
    required this.required,
    required this.dependency,
  });

  static FormModel fromJson(Map<String, dynamic> json) {
    final jsonType = json['type'];
    if (FormType.values.any((e) => e.name == jsonType)) {
      switch (FormType.values.byName(jsonType)) {
        case FormType.dropdown:
          return DropDownModel.fromJson(json);
        case FormType.multiselect:
          return MultiSelectModel.fromJson(json);
        case FormType.attendantsSelection:
          return AttendantsSelectionModel.fromJson(json);
        case FormType.segmented:
          return SegmentedControlModel.fromJson(json);
        case FormType.periodOfTime:
          return PeriodOfTimeModel.fromJson(json);
        case FormType.createMeetingButton:
          return CreateMeetingButtonModel.fromJson(json);
        case FormType.counter:
          return CounterModel.fromJson(json);
        case FormType.uploadImage:
          return UploadImageModel.fromJson(json);
        case FormType.attachment:
          return AttachmentsModel.fromJson(json);
        case FormType.comments:
          return CommentsModel.fromJson(json);
        case FormType.text:
          return TextModel.fromJson(json);
        case FormType.number:
          return NumberModel.fromJson(json);
        case FormType.textArea:
          return TextAreaModel.fromJson(json);
        case FormType.richText:
          return RichTextModel.fromJson(json);
        case FormType.datePicker:
          return DatePickerModel.fromJson(json);
        case FormType.timePicker:
          return TimePickerModel.fromJson(json);
        case FormType.collection:
          return CollectionFormModel.fromJson(json);
        case FormType.group:
          return GroupFormModel.fromJson(json);
        case FormType.unimplemented:
          break;
      }
    }
    return const UnImplementedFormModel();
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'dependency': dependency,
        'required': required,
      };

  @override
  List<Object?> get props => [
        type,
        title,
        dependency,
        required,
      ];
}

class FormDependencyModel extends Equatable {
  final String id;
  final String value;

  const FormDependencyModel({
    required this.id,
    required this.value,
  });

  factory FormDependencyModel.fromJson(Map<String, dynamic> json) => FormDependencyModel(
        id: validateString(json['id']?.toString()),
        value: validateString(json['value']?.toString()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
      };

  @override
  List<Object?> get props => [
        id,
        value,
      ];
}

class UnImplementedFormModel extends FormModel {
  const UnImplementedFormModel()
      : super(
          type: FormType.unimplemented,
          title: '',
          id: '',
          required: false,
          dependency: null,
        );
}
