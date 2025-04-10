import 'package:escola/core/models/event_for_user_model.dart';
import 'package:escola/core/models/tag_model.dart';
import 'package:escola/core/utils/valid_data.dart';

class SingleEventModel {
  final String id;
  final bool price_for_all_children;
  final String title;
  final String description;
  final String image_url;
  final List<String> listImageUrls;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currency;
  final String? priceBeforeDiscount;
  final String? priceAfterDiscount;
  final DateTime? deadLineForApproval;
  final String paymentInfo;
  final bool? requiredPaid;
  final bool? requiredApproval;
  // final bool? teacherAllowActions;
  final bool? all_parents;
  final bool? all_teachers;
  final EventForUserModel? eventForUserModel;
  final List<TagModel?>? tags;

  SingleEventModel({
    required this.id,
    required this.price_for_all_children,
    required this.title,
    required this.description,
    required this.image_url,
    required this.listImageUrls,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.priceBeforeDiscount,
    required this.priceAfterDiscount,
    required this.deadLineForApproval,
    required this.paymentInfo,
    required this.requiredApproval,
    required this.requiredPaid,
    // required this.teacherAllowActions,
    required this.eventForUserModel,
    required this.all_parents,
    required this.all_teachers,
    required this.tags,
  });

  //from json
  factory SingleEventModel.fromJson(Map<String, dynamic> json) {
    return SingleEventModel(
      id: validateString(json['id'].toString()),
      price_for_all_children: isSuccess(json['price_for_all_children'].toString()),
      title: validateString(json['title']),
      description: validateString(json['description']),
      image_url: validateString(json['image']),
      listImageUrls: List<String>.from(json['slider'] ?? []),
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      currency: validateString(json['currency']),
      priceBeforeDiscount: json['price'],
      priceAfterDiscount: json['price_after_discount'],
      deadLineForApproval: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      paymentInfo: validateString(json['payment_info'].toString()),
      requiredApproval: isSuccess(json['has_approval'] ?? json['has_approval']),
      requiredPaid: isSuccess(json['has_payment']),
      // teacherAllowActions: isSuccess(json['teacher_allow_actions']),
      eventForUserModel: EventForUserModel.fromJson(validateMap(json)),
      all_parents: isSuccess(json['all_parents']),
      all_teachers: isSuccess(json['all_teachers']),
      tags: validateDataList(json['tags'], (e) => TagModel.fromJson(e)),
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price_for_all_children': price_for_all_children,
      'title': title,
      'description': description,
      'image_url': image_url,
      'list_image_urls': listImageUrls,
      'start_date': startDate,
      'end_date': endDate,
      'currency': currency,
      'price_before_discount': priceBeforeDiscount,
      'price_after_discount': priceAfterDiscount,
      'dead_line_for_approval': deadLineForApproval,
      'payment_info': paymentInfo,
      'required_approval': requiredApproval,
      // 'teacher_allow_actions': teacherAllowActions,
      'registration': eventForUserModel?.toJson(),
      'all_parents': all_parents,
      'all_teachers': all_teachers,
      'required_paid': requiredPaid,
      'tags': tags,
    };
  }
}
