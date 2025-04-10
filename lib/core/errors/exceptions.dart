import 'package:flutter/material.dart';

class ServerException implements Exception {
  final String message;

  ServerException({this.message = "Server Error"});
}

class NetworkException implements Exception {}

void printErrors(Object error, StackTrace stackTrace) {
  debugPrint("Error is : $error");
  debugPrint("StackTrace is : $stackTrace");
}
