import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/presentation/state/posts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_post_api.dart';

void main() {
  late FakePostApi api;
  late PostsProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakePostApi();
    provider = PostsProvider(PostRepository(api, PostCache()));
  });

  // Тест 5
  test('Фильтрация постов по автору и по заголовку', () {
    const posts = [
      Post(id: 1, userId: 1, title: 'Flutter basics', body: '...'),
      Post(id: 2, userId: 2, title: 'Dart tips', body: '...'),
      Post(id: 3, userId: 1, title: 'Hello world', body: '...'),
    ];

    final byUser = filterPosts(posts, userId: 1);
    expect(byUser.map((p) => p.id), [1, 3]);

    final byTitle = filterPosts(posts, query: 'flutter');
    expect(byTitle.map((p) => p.id), [1]);

    final sortedDesc = filterPosts(posts, ascending: false);
    expect(sortedDesc.map((p) => p.id), [3, 2, 1]);
  });

  // Тест 6
  test('Одна и та же страница не загружается дважды', () async {
    await provider.loadFirstPage();
    expect(provider.visiblePosts.length, 10);

    // Два вызова подряд (как при быстрой прокрутке)
    await Future.wait([provider.loadNextPage(), provider.loadNextPage()]);

    expect(api.pageCalls[2], 1); // страница 2 запрошена ровно один раз
    expect(provider.visiblePosts.length, 20);
    final ids = provider.visiblePosts.map((p) => p.id).toSet();
    expect(ids.length, 20); // дубликатов нет
  });

  // Доп.: после смены фильтра старые результаты не смешиваются с новыми
  test('Смена автора сбрасывает страницы', () async {
    await provider.loadFirstPage();
    await provider.setUserFilter(2);

    expect(provider.visiblePosts.length, 10);
    expect(provider.visiblePosts.every((p) => p.userId == 2), true);
  });

  // Доп.: при сетевой ошибке остаются кэшированные данные
  test('Офлайн: показываются сохранённые посты', () async {
    await provider.loadFirstPage(); // первая загрузка сохранила кэш

    // Новый запуск приложения без интернета
    api.error = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.connectionError,
    );
    final offlineProvider = PostsProvider(PostRepository(api, PostCache()));
    await offlineProvider.loadFirstPage();

    expect(offlineProvider.status, ListStatus.cached);
    expect(offlineProvider.visiblePosts.length, 10);
    expect(offlineProvider.errorMessage, isNotNull);
  });
}
