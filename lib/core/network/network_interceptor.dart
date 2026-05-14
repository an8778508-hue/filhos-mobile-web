import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/constants/static_config.dart';
import 'package:escola/core/utils/print.dart';

abstract class NetworkInterceptor {
  void addInterceptor();
}

class DioInterceptorImpl implements NetworkInterceptor {
  final Dio dioInstance;
  final LocalDatabaseRepo localDatabase;

  DioInterceptorImpl(
    this.dioInstance,
    this.localDatabase,
  );

  @override
  void addInterceptor() async {
    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: _handleOnRequest,
        onResponse: _handleOnResponse,
        onError: _handleOnError,
      ),
    );
  }

  void _handleOnRequest(
    RequestOptions req,
    RequestInterceptorHandler handler,
  ) async {
    //todo
    final UserModel? user = UserBloc.get.state.user;
    if (user != null) {
      final String? token = user.accessToken;

      final int schoolId = user.schoolId ?? int.parse(StaticConfig.schoolId);
      req.headers["school"] = schoolId.toString();
      req.headers["school_id"] = schoolId.toString();

      // add locale key
      try {
        String locale = UserBloc.get.state.languageWithCode;
        req.headers["lang"] = locale;
      } catch (e) {
        printR("Error in get locale", e);
        req.headers["lang"] = "pt_Br";
      }

      // add Token
      if (token != null) {
        req.headers["Authorization"] = "Bearer $token";
      }
    }
    printRequestInfo(req);
    handler.next(req);
  }

  void _handleOnResponse(Response response, handler) {
    printR("Request Response status code is :", " ${response.statusCode}");
    try {
      printR("Request Response is :", " ${getPrettyJSONString(jsonDecode(response.data))}");
    } catch (e) {
      printR("Request Response is :", " $response");
    }

    handler.next(response);
  }

  // check if token is expired

  static void printRequestInfo(RequestOptions req) {
    printR('Request url is :', '${req.baseUrl}${req.path}');
    printR('Request headers is :', '${req.headers}');
    printR('Request Type is :', ' ${req.method}');
    if (req.data is FormData) {
      printR('Request Body fields is :', ' ${(req.data as FormData).fields}');
      printR('Request Body files is :', ' ${(req.data as FormData).files}');
    } else {
      try {
        printR('Request Body is :', ' ${getPrettyJSONString(req.data)}');
      } catch (e) {
        printR('Request Body is :', ' ${req.data}');
      }
    }
    printR('Request parameters is :', '${req.queryParameters}');
  }

  // Guards against re-entrant logout loops: a 401 on the logout request itself
  // (or on a token-revoke) must not trigger another forced-logout cascade.
  bool _loggingOut = false;

  _handleOnError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final status = error.response?.statusCode;
    if (status == 401 && !_loggingOut && UserBloc.get.state.user != null) {
      _loggingOut = true;
      try {
        await UserBloc.get.loggedOut();
      } catch (e) {
        printR('401 forced-logout failed', e);
      } finally {
        _loggingOut = false;
      }
    }
    return handler.next(error);
  }
}
