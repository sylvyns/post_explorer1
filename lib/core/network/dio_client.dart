import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_interceptor.dart';

/// Единственный экземпляр Dio на всё приложение.
/// Новый Dio для каждого запроса НЕ создаётся.
class DioClient {
  DioClient._(); // нельзя создать объект снаружи

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  static final Dio instance = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10), // таймаут подключения
        receiveTimeout: const Duration(seconds: 10), // таймаут ответа
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(ApiInterceptor());

    // LogInterceptor печатает запросы/ответы в консоль только в debug-режиме.
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (line) => debugPrint(line.toString()),
      ));
    }
    return dio;
  }
}
