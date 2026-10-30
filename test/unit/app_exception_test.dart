// СРС 9 — Unit Test: преобразование ошибок в понятные сообщения.
//
// AppException.from() получает «сырую» ошибку (Dio, JSON, любую другую)
// и возвращает тип ошибки + текст, который увидит пользователь.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/core/error/app_exception.dart';
import 'package:post_explorer/data/models/post.dart';

/// Создаёт DioException нужного типа (и, если надо, с HTTP-кодом).
DioException dioError(DioExceptionType type, {int? statusCode, Object? error}) {
  final options = RequestOptions(path: '/posts');
  return DioException(
    requestOptions: options,
    type: type,
    error: error,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  group('AppException.from — сетевые ошибки', () {
    test('все виды таймаута -> ErrorType.timeout', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = AppException.from(dioError(type));
        expect(e.type, ErrorType.timeout, reason: '$type');
        expect(e.message, 'Сервер долго не отвечает. Попробуйте ещё раз.');
      }
    });

    test('нет интернета -> ErrorType.noConnection', () {
      final e = AppException.from(dioError(DioExceptionType.connectionError));
      expect(e.type, ErrorType.noConnection);
      expect(e.message, 'Нет подключения к интернету.');
    });

    test('SocketException внутри unknown тоже считается «нет интернета»', () {
      final e = AppException.from(dioError(
        DioExceptionType.unknown,
        error: const SocketException('Failed host lookup'),
      ));
      expect(e.type, ErrorType.noConnection);
    });
  });

  group('AppException.from — HTTP-коды', () {
    test('404 -> client, «Данные не найдены (404).»', () {
      final e = AppException.from(
          dioError(DioExceptionType.badResponse, statusCode: 404));
      expect(e.type, ErrorType.client);
      expect(e.statusCode, 404);
      expect(e.message, 'Данные не найдены (404).');
    });

    test('400 -> client с кодом в тексте', () {
      final e = AppException.from(
          dioError(DioExceptionType.badResponse, statusCode: 400));
      expect(e.type, ErrorType.client);
      expect(e.message, 'Ошибка запроса (код 400).');
    });

    test('500 и 503 -> server', () {
      for (final code in [500, 503]) {
        final e = AppException.from(
            dioError(DioExceptionType.badResponse, statusCode: code));
        expect(e.type, ErrorType.server);
        expect(e.statusCode, code);
        expect(e.message, 'Сервер временно недоступен (код $code).');
      }
    });
  });

  group('AppException.from — некорректные данные и прочее', () {
    test('поле неверного типа в JSON -> ErrorType.parse', () {
      // id пришёл строкой вместо числа
      final badJson = {'id': 'один', 'userId': 1, 'title': 'T', 'body': 'B'};

      Object? raw;
      try {
        Post.fromJson(badJson);
      } catch (e) {
        raw = e;
      }

      expect(raw, isNotNull);
      expect(AppException.from(raw!).type, ErrorType.parse);
    });

    test('FormatException -> ErrorType.parse', () {
      final e = AppException.from(const FormatException('bad json'));
      expect(e.type, ErrorType.parse);
      expect(e.message, 'Сервер вернул некорректные данные.');
    });

    test('отменённый запрос и любая другая ошибка -> unknown', () {
      expect(AppException.from(dioError(DioExceptionType.cancel)).type,
          ErrorType.unknown);
      expect(AppException.from(Exception('???')).type, ErrorType.unknown);
    });

    test('готовая AppException возвращается без изменений', () {
      const original = AppException(ErrorType.server, 'Ошибка', statusCode: 502);
      expect(identical(AppException.from(original), original), isTrue);
    });
  });
}
