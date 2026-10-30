import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/core/error/app_exception.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_post_api.dart';

void main() {
  late FakePostApi api;
  late PostRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({}); // кэш в памяти
    api = FakePostApi();
    repository = PostRepository(api, PostCache());
  });

  // Тест 3
  test('Посты успешно загружаются через репозиторий и сохраняются в кэш',
      () async {
    final posts = await repository.fetchPosts(page: 1);

    expect(posts.length, 10);
    expect(posts.first.id, 1);

    final cached = await repository.getCachedPosts(null);
    expect(cached?.length, 10);
  });

  // Тест 4
  test('Ошибка сервера 500 превращается в AppException(server)', () async {
    final options = RequestOptions(path: '/posts');
    api.error = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: options, statusCode: 500),
    );

    await expectLater(
      repository.fetchPosts(page: 1),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', ErrorType.server)
          .having((e) => e.statusCode, 'statusCode', 500)),
    );
  });

  // Доп.: нет интернета
  test('Нет соединения -> AppException(noConnection)', () async {
    api.error = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.connectionError,
    );

    await expectLater(
      repository.fetchPosts(page: 1),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', ErrorType.noConnection)),
    );
  });
}
