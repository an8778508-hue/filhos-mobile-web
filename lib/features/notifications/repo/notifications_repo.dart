import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/notifications/models/notification_model.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/my_app.dart';

class NotificationsRepo {
   String get  notificationsEndpoint => mainKey.currentContext?.isProfessors == true ?'auth/notifications':'auth/notifications';

  final NetworkClientRepository networkClient;
  NotificationsRepo({required this.networkClient});

  Future<Either<Failure, List<NotificationModel>>> getNotificationsPaginated(
      int page) async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: notificationsEndpoint,
        queryParameters: {
          'page': '$page',
        },
      ),
      onSuccess: (json) {
        final children = (json['data'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
        return children;
      },
    );
  }
}
