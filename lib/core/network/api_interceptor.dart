import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Собственный interceptor: добавляет технические заголовки к каждому запросу
class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';
    options.headers['X-App-Name'] = 'PostExplorer';
    options.headers['X-App-Version'] = '1.0.0';
    options.headers['X-Request-Time'] = DateTime.now().toIso8601String();
    handler.next(options); // передаём запрос дальше
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[HTTP ERROR] ${err.requestOptions.method} '
        '${err.requestOptions.uri} -> ${err.type} ${err.response?.statusCode}');
    handler.next(err); // ошибку дальше превратит в AppException репозиторий
  }
}
