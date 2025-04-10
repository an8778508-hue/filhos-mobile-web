import 'package:equatable/equatable.dart';

class NetworkRequest extends Equatable {
  final String url;
  final Map<String, dynamic>? headers;
  final HttpMethod method;
  final Object? body;
  final Map<String, dynamic>? queryParameters;

  const NetworkRequest({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    this.queryParameters,
  });

  @override
  List<Object?> get props => [url, headers, method, body, queryParameters];
}

class NetworkResponse extends Equatable {
  final int? statusCode;
  final String? statusMessage;
  final String data;

  const NetworkResponse(
      {this.statusCode, this.statusMessage, required this.data});

  @override
  List<Object?> get props => [statusCode, statusMessage, data];
}

enum HttpMethod { get, post, put, patch, delete }
