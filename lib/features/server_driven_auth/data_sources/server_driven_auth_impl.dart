import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/server_driven_auth/data_sources/server_driven_auth_repository.dart';
import 'package:escola/features/server_driven_auth/models/auth_action_response.dart';
import 'package:escola/features/server_driven_auth/models/check_identifier_request.dart';
import 'package:escola/features/server_driven_auth/models/forgot_password_request.dart';
import 'package:escola/features/server_driven_auth/models/otp_verify_request.dart';
import 'package:escola/features/server_driven_auth/models/sda_login_request.dart';
import 'package:escola/features/server_driven_auth/models/self_register_request.dart';
import 'package:escola/features/server_driven_auth/models/set_password_request.dart';

/// Mirrors the patterns in `lib/features/login/data_sources/login_impl.dart`:
///   * `NetworkClient.handleRequest<T>` → `Either<Failure, T>` (Principle III).
///   * Terminal endpoints parse the legacy login envelope `{data, access_token}`
///     via `UserModel.fromJson(json['data'])` so `UserBloc.loggedIn` is unchanged.
///   * Step endpoints parse the new uniform envelope via
///     `AuthActionResponse.fromJson(json)`.
class ServerDrivenAuthImpl extends ServerDrivenAuthRepository {
  final NetworkClientRepository networkClient;

  ServerDrivenAuthImpl(this.networkClient);

  @override
  Future<Either<Failure, AuthActionResponse>> checkIdentifier(
      CheckIdentifierRequest request) {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: ServerDrivenAuthRepository.checkIdentifierEndpoint,
        body: request.toJson(),
      ),
      onSuccess: (json) =>
          AuthActionResponse.fromJson(_asMap(json)),
    );
  }

  @override
  Future<Either<Failure, UserModel>> setInitialPassword(
      SetPasswordRequest request) {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: ServerDrivenAuthRepository.setInitialPasswordEndpoint,
        body: request.toJson(),
      ),
      onSuccess: (json) =>
          UserModel.fromJson(_asMap(_asMap(json)['data'])),
    );
  }

  @override
  Future<Either<Failure, AuthActionResponse>> selfRegister(
      SelfRegisterRequest request) {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: ServerDrivenAuthRepository.selfRegisterEndpoint,
        body: request.toJson(),
      ),
      onSuccess: (json) => AuthActionResponse.fromJson(_asMap(json)),
    );
  }

  @override
  Future<Either<Failure, AuthActionResponse>> verifyEmailOtp(
      OtpVerifyRequest request) {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: ServerDrivenAuthRepository.verifyEmailOtpEndpoint,
        body: request.toJson(),
      ),
      onSuccess: (json) => AuthActionResponse.fromJson(_asMap(json)),
    );
  }

  @override
  Future<Either<Failure, UserModel>> login(SdaLoginRequest request) {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: ServerDrivenAuthRepository.loginEndpoint,
        body: request.toJson(),
      ),
      onSuccess: (json) =>
          UserModel.fromJson(_asMap(_asMap(json)['data'])),
    );
  }

  @override
  Future<Either<Failure, AuthActionResponse>> forgotPassword(
      ForgotPasswordRequest request) {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: ServerDrivenAuthRepository.forgotPasswordEndpoint,
        body: request.toJson(),
      ),
      onSuccess: (json) => AuthActionResponse.fromJson(_asMap(json)),
    );
  }

  @override
  Future<Either<Failure, AuthActionResponse>> verifyResetOtp(
      OtpVerifyRequest request) {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: ServerDrivenAuthRepository.verifyResetOtpEndpoint,
        body: request.toJson(),
      ),
      onSuccess: (json) => AuthActionResponse.fromJson(_asMap(json)),
    );
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(SetPasswordRequest request) {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: ServerDrivenAuthRepository.resetPasswordEndpoint,
        body: request.toJson(),
      ),
      onSuccess: (_) => unit,
    );
  }

  /// Defensive map coercion — the backend SHOULD return a `Map<String, dynamic>`
  /// at the top level for every auth response, but old proxies / null bodies
  /// can produce surprising shapes. Returning `{}` lets the parser surface a
  /// clean `AuthAction.unknown` (or empty UserModel) instead of crashing.
  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }
}
