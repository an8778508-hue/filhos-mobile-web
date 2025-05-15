import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/user/data_source/user_repo.dart';

class UserDataImpl extends UserRepo {
  final NetworkClientRepository networkClient;

  UserDataImpl({required this.networkClient});

  @override
  Future<Either<Failure, UserModel>> getUser() async {
    return await networkClient.handleRequest<UserModel>(
      NetworkRequest(
        method: HttpMethod.get,
        url: userDataEndpoint,
      ),
      onSuccess: (json) {
        final userData = json['data'];
        return UserModel.fromJson(userData);
      },
    );
  }

  @override
  Future<Either<Failure, void>> updateDeviceToken(String token,String? old_device_token, String uuid) async {
    return await networkClient.handleRequest<void>(
      NetworkRequest(method: HttpMethod.post, url: updateDeviceTokenEndpoint, body: {
        'device_id': uuid,
        'new_device_token': token,
        'old_device_token': old_device_token,
        'lang': UserBloc.get.state.language,
      }),
    );
  }
}
