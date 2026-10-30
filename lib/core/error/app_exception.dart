import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Виды ошибок, которые различает приложение.
enum ErrorType { noConnection, timeout, client, server, parse, unknown }

/// Единая ошибка приложения.

class AppException implements Exception {
  final ErrorType type;
  final String message;
  final int? statusCode;

  const AppException(this.type, this.message, {this.statusCode});

  /// Превращает ЛЮБУЮ ошибку (Dio, JSON, другую) в AppException.

  factory AppException.from(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    // Технические детали — только в лог разработчика.
    debugPrint('[AppException] $error');
    if (stackTrace != null) debugPrint('$stackTrace');

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const AppException(
              ErrorType.timeout, 'Сервер долго не отвечает. Попробуйте ещё раз.');

        case DioExceptionType.connectionError:
          return const AppException(
              ErrorType.noConnection, 'Нет подключения к интернету.');

        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? 0;
          if (code >= 500) {
            return AppException(ErrorType.server,
                'Сервер временно недоступен (код $code).',
                statusCode: code);
          }
          if (code == 404) {
            return AppException(ErrorType.client, 'Данные не найдены (404).',
                statusCode: code);
          }
          return AppException(ErrorType.client, 'Ошибка запроса (код $code).',
              statusCode: code);

        default:
          // Иногда отсутствие сети приходит как unknown с SocketException внутри.
          if (error.error.toString().contains('SocketException')) {
            return const AppException(
                ErrorType.noConnection, 'Нет подключения к интернету.');
          }
          return const AppException(ErrorType.unknown, 'Что-то пошло не так.');
      }
    }

    // Ошибки преобразования JSON: не тот тип поля, нет обязательного поля и т.п.
    if (error is TypeError || error is FormatException) {
      return const AppException(
          ErrorType.parse, 'Сервер вернул некорректные данные.');
    }

    return const AppException(ErrorType.unknown, 'Что-то пошло не так.');
  }

  @override
  String toString() => 'AppException($type, $message)';
}
