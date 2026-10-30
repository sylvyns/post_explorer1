import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/remote/post_api.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/presentation/screens/create_post_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock-адаптер Dio: вместо интернета сразу возвращает готовый ответ.
/// Так тестируется НАСТОЯЩИЙ Retrofit-код без сети.
class FakeAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final sent = options.data as Map<String, dynamic>;
    return ResponseBody.fromString(
      jsonEncode({...sent, 'id': 101}), // так отвечает JSONPlaceholder
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('POST /posts через Retrofit с mock-адаптером Dio', () async {
    SharedPreferences.setMockInitialValues({});
    final adapter = FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    final repository = PostRepository(PostApi(dio), PostCache());

    final post = await repository.createPost(
      title: 'Мой пост',
      body: 'Текст моего поста',
      userId: 1,
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, '/posts');
    expect(post.id, 101);
    expect(post.title, 'Мой пост');
    expect(post.isLocal, true); // помечен «создан локально»
  });

  test('Валидация формы создания поста', () {
    expect(validateTitle(''), isNotNull);
    expect(validateTitle('abc'), isNotNull); // меньше 5
    expect(validateTitle('Нормальный заголовок'), isNull);
    expect(validateBody('short'), isNotNull); // меньше 10
    expect(validateBody('Достаточно длинный текст'), isNull);
  });
}
