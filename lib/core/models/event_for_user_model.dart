import 'package:escola/core/utils/valid_data.dart';

class EventForUserModel {
  // final String eventId;
  // final String userId;
  final bool? isApproved;
  final String approvalUserId;
  final String approvalUserName;
  final String approvalImageUrl;
  final String payment_receipt;
  final DateTime? approvedDate;
  final DateTime? payment_date;
  final bool? isPaid;

  const EventForUserModel({
    // required this.eventId,
    // required this.userId,
    required this.isApproved,
    required this.approvalUserId,
    required this.approvalUserName,
    required this.approvalImageUrl,
    required this.payment_receipt,
    required this.approvedDate,
    required this.payment_date,
    required this.isPaid,
  });

  //from json
  factory EventForUserModel.fromJson(Map<String, dynamic> json) {
    return EventForUserModel(
      // eventId: validateString(json['event_id']),
      // userId: validateString(json['user_id']),
      isApproved: json['approved']!=null ? isSuccess(json['approved']) : null,
      isPaid: isSuccess(json['paid']),
      approvedDate: json['approved_date'] != null ? DateTime.parse(json['approved_date']) : null,
      payment_date: json['payment_date'] != null ? DateTime.parse(json['payment_date']) : null,
      approvalUserId: validateString(json['approved_user']?['id']),
      approvalUserName: validateString(json['approved_user']?['name']),
      approvalImageUrl: validateString(json['approved_user']?['avatar']),
      payment_receipt: validateString(json['payment_receipt']),
    );
  }

  //to json
  Map<String, dynamic> toJson() {
    return {
      // 'event_id': eventId,
      // 'user_id': userId,
      'approval_user_id': approvalUserId,
      'paid': isPaid,
      'is_approved': isApproved,
      'approved_date': approvedDate,
      'approval_user_name': approvalUserName,
      'approval_image_url': approvalImageUrl,
      'payment_receipt': payment_receipt,
    };
  }

  copyWith({required bool isApproved}) {
    return EventForUserModel(
      // eventId: eventId,
      // userId: userId,
      approvalUserId: approvalUserId,
      isPaid: isPaid,
      isApproved: isApproved,
      approvedDate: approvedDate,
      payment_date: payment_date,
      payment_receipt: payment_receipt,
      approvalUserName: approvalUserName,
      approvalImageUrl: approvalImageUrl,
    );
  }
}
