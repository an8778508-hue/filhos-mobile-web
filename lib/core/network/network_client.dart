import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/exceptions.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/crashlytics_helper.dart';
import 'package:escola/core/network/network_interceptor.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/constants/api_const.dart';
import 'package:flutter/foundation.dart';

abstract class NetworkClientRepository {
  Future<NetworkResponse> sendRequest(NetworkRequest request);

  Future<Either<Failure, T>> handleRequest<T>(NetworkRequest request,
      {T Function(dynamic)? onSuccess, dynamic testJson, bool testError = false});

  void setTimeout(int seconds);
}

class NetworkClient implements NetworkClientRepository {
  final Dio _dioInstance;
  final NetworkInterceptor _interceptor;
  final CrashlyticsRepository _crashlytics;

  NetworkClient(this._dioInstance, this._interceptor, this._crashlytics) {
    _interceptor.addInterceptor();
    setTimeout();
    _dioInstance.options.responseType = ResponseType.plain;
    _dioInstance.options.baseUrl = ApiConst.baseUrl;
  }

  @override
  Future<NetworkResponse> sendRequest(NetworkRequest request) async {
    try {
      final String url = request.url.startsWith('/') ? request.url.replaceFirst('/', '') : request.url;

      final Response networkResponse = await _dioInstance.request(
        url,
        data: request.body,
        queryParameters: request.queryParameters,
        options: Options(
          method: request.method.name,
          headers: request.headers,
        ),
      );

      return _adjustResponse(networkResponse);
    } on Exception catch (error) {
      throw _throwError(error);
    }
  }

  // Defaults sized for JSON endpoints. For media uploads call `setTimeout(...)`
  // with a larger value or use a dedicated multipart helper.
  static const Duration _defaultConnectTimeout = Duration(seconds: 20);
  static const Duration _defaultReceiveTimeout = Duration(seconds: 30);
  static const Duration _defaultSendTimeout = Duration(seconds: 60);

  @override
  void setTimeout([int? seconds]) {
    if (seconds == null) {
      _dioInstance.options.connectTimeout = _defaultConnectTimeout;
      _dioInstance.options.receiveTimeout = _defaultReceiveTimeout;
      _dioInstance.options.sendTimeout = _defaultSendTimeout;
    } else {
      final d = Duration(seconds: seconds);
      _dioInstance.options.connectTimeout = d;
      _dioInstance.options.receiveTimeout = d;
      _dioInstance.options.sendTimeout = d;
    }
  }

  NetworkResponse _adjustResponse(Response? response) {
    if (response == null || (response.statusCode ?? 500) >= 400) {
      return _throwResponseError(response);
    }

    return NetworkResponse(
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      data: response.data.toString(),
    );
  }

  @override
  Future<Either<Failure, T>> handleRequest<T>(NetworkRequest request,
      {T Function(dynamic p1)? onSuccess, dynamic testJson, bool testError = false}) async {
    try {
      if (testError) return const Left(ServerFailure());
      if (testJson != null && onSuccess != null) {
        return Right(onSuccess(json.decode(testJson)));
      }
      final requestResult = await sendRequest(request);
      if (onSuccess == null) return Right(() {} as T);
      return Right(onSuccess(json.decode(requestResult.data)));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e, s) {
      debugPrint("Error is : $e\n" "Stack is : $s ");
      return const Left(ServerFailure());
    }
  }

  _throwError(Exception error) {
    if (error is DioException) {
      debugPrint("Error is : $error");
      debugPrint("Error path is : ${error.requestOptions.path}");
      final errorLength = error.response?.data.toString().length ?? 0;
      print(
          "Error response is : ${error.response?.data.toString()}");
      debugPrint(
          "Error response is : ${error.response?.data.toString().substring(0, errorLength > 100 ? 100 : errorLength)}");

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw NetworkException();
        case DioExceptionType.badResponse:
        default:
          throw _throwResponseError(error.response);
      }
    } else {
      debugPrint("Error is : $error");
      throw ServerException();
    }
  }

  _throwResponseError(Response? response) {
    try {
      if (response?.statusCode == 401) {
        throw ServerException(message: "Unauthorized");
      } else if (response?.statusCode == 403) {
        throw ServerException(message: "Forbidden");
      } else if (response?.statusCode == 500) {
        // send to crashlytics
        _sendCrashReport(response);
        throw ServerException();
      } else {
        Map<String, dynamic> map = jsonDecode(response?.data);

        if (map.keys.contains("errors") && map['errors'] is Map<String, dynamic>) {
          // get the error code error translations
          final errorMap = (map['errors'] as Map<String, dynamic>);
          final list = errorMap.values.map((e) => e).toList();
          String myError = '';
          for (var element in list) {
            print('NetworkClient._throwResponseError ${element.runtimeType}');
            if (element is List) {
              for (var s in element) {
                myError += '\n$s';
              }
            } else {
              myError += '\n$element';
            }
          }

          throw ServerException(message: myError.replaceFirst('\n', ''));
        } else if ((map.keys.contains("message"))) {
          // get the error code error translations
          throw ServerException(message: map['message']);
        } else {
          throw ServerException();
        }
      }
    } on Exception catch (e, s) {
      printErrors(e, s);
      rethrow;
    } catch (e, s) {
      printErrors(e, s);
      throw ServerException();
    }
  }

  void _sendCrashReport(Response? response) {
    _crashlytics.sendCrashReport(
      response?.statusMessage,
      StackTrace.current,
      info: _requestInfo(response?.requestOptions),
    );
  }

  /// Header keys we MUST strip before sending to Crashlytics — LGPD risk.
  static const Set<String> _sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'school',
    'school_id',
  };

  /// Paths whose request/response bodies are fully redacted (LGPD — email + OTP codes).
  static const Set<String> _sensitivePathPrefixes = {
    'auth/email-otp/',
  };

  /// Body keys we MUST strip — Brazilian PII + medical data.
  static const Set<String> _sensitiveBodyKeys = {
    'password',
    'token',
    'access_token',
    'refresh_token',
    'cpf',
    'cpf_num',
    'phone',
    'phone_number',
    'email',
    'medicine',
    'medication',
    'prescription',
    'dosage',
    'avatar',
    'image',
    'images',
    'firebase_id_token',
  };

  Map<String, dynamic> _redactHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return const {};
    return {
      for (final entry in headers.entries)
        entry.key:
            _sensitiveHeaders.contains(entry.key.toLowerCase()) ? '[redacted]' : entry.value,
    };
  }

  String _redactBody(dynamic body) {
    if (body == null) return 'null';
    if (body is FormData) {
      return 'FormData(${body.fields.length} fields, ${body.files.length} files) [redacted]';
    }
    if (body is Map) {
      final redacted = <String, dynamic>{};
      body.forEach((k, v) {
        redacted[k.toString()] =
            _sensitiveBodyKeys.contains(k.toString().toLowerCase()) ? '[redacted]' : v;
      });
      return redacted.toString();
    }
    return '[non-map body redacted]';
  }

  bool _isSensitivePath(String? path) {
    if (path == null) return false;
    return _sensitivePathPrefixes.any((p) => path.contains(p));
  }

  String _requestInfo(RequestOptions? requestOptions) {
    final body = _isSensitivePath(requestOptions?.path)
        ? '[fully redacted — sensitive endpoint]'
        : _redactBody(requestOptions?.data);
    return "Crashlytics : Request url is : ${requestOptions?.baseUrl}${requestOptions?.path}"
        "\nRequest headers is : ${_redactHeaders(requestOptions?.headers)}"
        "\nRequest Type is : ${requestOptions?.method}"
        "\nRequest Body is : $body\n";
  }
}
