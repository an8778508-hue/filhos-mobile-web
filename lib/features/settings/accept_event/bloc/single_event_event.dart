import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

sealed class SingleEventEvent extends Equatable {
  const SingleEventEvent();

  @override
  List<Object> get props => [];
}

final class SingleEventFetchedSuccessfullyEvent extends SingleEventEvent {}

final class FetchSingleEvent extends SingleEventEvent {
  final String eventId;

  const FetchSingleEvent({required this.eventId});
}

class ApproveEvent extends SingleEventEvent {
  final String eventId;

  const ApproveEvent({
    required this.eventId,
  });
}

class PaymentEvent extends SingleEventEvent {
  final String eventId;
  final XFile image;

  const PaymentEvent({
    required this.eventId,
    required this.image,
  });
}

class NotApproveEvent extends SingleEventEvent {
  final String eventId;

  const NotApproveEvent({
    required this.eventId,
  });
}
