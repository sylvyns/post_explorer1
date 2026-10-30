// СРС 9 — Unit Test: логика PostsProvider (состояние экрана списка).
//
// Вместо интернета используется FakePostApi (30 постов, по 10 на автора),
// вместо SharedPreferences — кэш в памяти.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/presentation/state/posts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_post_api.dart';

DioException noInternet() => DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.connectionError,
    );

void main() {
  late FakePostApi api;
  late PostsProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakePostApi();
    provider = PostsProvider(PostRepository(api, PostCache()));
  });

  test('успешная загрузка: статус success и 10 постов', () async {
    await provider.loadFirstPage();

    expect(provider.status, ListStatus.success);
    expect(provider.visiblePosts.length, PostRepository.pageSize);
    expect(provider.hasMore, isTrue);
  });

  test('ошибка без кэша: статус error и понятное сообщение', () async {
    api.error = noInternet();

    await provider.loadFirstPage();

    expect(provider.status, ListStatus.error);
    expect(provider.errorMessage, 'Нет подключения к интернету.');
    expect(provider.visiblePosts, isEmpty);
  });

  test('сервер вернул пустой список: статус empty', () async {
    api.allPosts.clear();

    await provider.loadFirstPage();

    expect(provider.status, ListStatus.empty);
    expect(provider.hasMore, isFalse);
  });

  test('пагинация останавливается, когда посты закончились', () async {
    await provider.loadFirstPage();
    while (provider.hasMore) {
      await provider.loadNextPage();
    }

    expect(provider.visiblePosts.length, 30);
    expect(api.pageCalls[4], 1); // 4-я страница пустая -> hasMore = false

    await provider.loadNextPage();
    expect(api.pageCalls[5], isNull); // лишний запрос не отправлен
  });

  test('ошибка подгрузки не стирает список, «Повторить» догружает страницу',
      () async {
    await provider.loadFirstPage();

    api.error = noInternet();
    await provider.loadNextPage();
    expect(provider.loadMoreError, isNotNull);
    expect(provider.visiblePosts.length, 10); // старые посты на месте

    api.error = null;
    await provider.retryNextPage();
    expect(provider.loadMoreError, isNull);
    expect(provider.visiblePosts.length, 20);
  });

  test('локальный пост показывается первым и скрывается поиском', () async {
    await provider.loadFirstPage();
    provider.addLocalPost(
      const Post(id: 101, userId: 1, title: 'Мой пост', body: 'Текст', isLocal: true),
    );

    expect(provider.visiblePosts.first.id, 101);
    expect(provider.visiblePosts.first.isLocal, isTrue);
    expect(provider.visiblePosts.length, 11);

    provider.setSearch('Post number');
    expect(provider.visiblePosts.any((p) => p.isLocal), isFalse);
  });

  test('toggleSort и resetFilters', () async {
    await provider.loadFirstPage();

    provider.toggleSort();
    expect(provider.sortAscending, isFalse);
    expect(provider.visiblePosts.first.id, 10);

    provider.setSearch('flutter');
    expect(provider.visiblePosts.map((p) => p.id), [5]);

    await provider.resetFilters();
    expect(provider.sortAscending, isTrue);
    expect(provider.searchQuery, '');
    expect(provider.visiblePosts.first.id, 1);
    expect(provider.visiblePosts.length, 10);
  });
}
