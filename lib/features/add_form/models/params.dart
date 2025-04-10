import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';

class CreateFormParams extends Equatable {
  final FormType type;
  final Object value;

  const CreateFormParams({
    required this.type,
    required this.value,
  });

  factory CreateFormParams.fromJson(Map<String, dynamic> json) => CreateFormParams(
        type: FormType.values.safeFirstWhere((e) => e.name == json['type'].toString()) ?? FormType.unimplemented,
        value: json['value'],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
      };

  @override
  List<Object?> get props => [
        type,
        value,
      ];
}

class UploadFileParam extends Equatable {
  final String? id;
  final String url;

  const UploadFileParam({
    this.id,
    required this.url,
  });

  factory UploadFileParam.fromJson(Map<String, dynamic> json) => UploadFileParam(
        id: validateString(json['id'].toString()),
        url: validateString(json['url'].toString()),
      );

  Map<String, dynamic> toJson() => {
        if (validString(id)) 'id': id,
        'url': url,
      };

  @override
  List<Object?> get props => [
        id,
        url,
      ];
}
