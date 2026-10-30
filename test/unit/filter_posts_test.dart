// СРС 9 — Unit Test: фильтрация и сортировка списка постов.
//
// filterPosts() — чистая функция из posts_provider.dart. Именно её
// использует экран списка для поиска по заголовку, фильтра по автору
// и сортировки по ID.

import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/presentation/state/posts_provider.dart';

void main() {
  // Посты специально идут НЕ по порядку id.
  late List<Post> posts;

  setUp(() {
    posts = [
      const Post(id: 3, userId: 1, title: 'Hello Flutter', body: '...'),
      const Post(id: 1, userId: 2, title: 'Dart tips', body: '...'),
      const Post(id: 2, userId: 1, title: 'FLUTTER testing', body: '...'),
      const Post(id: 4, userId: 3, title: 'Provider state', body: '...'),
    ];
  });

  List<int> ids(List<Post> list) => list.map((p) => p.id).toList();

  group('filterPosts', () {
    test('без фильтров возвращает все посты, отсортированные по id', () {
      expect(ids(filterPosts(posts)), [1, 2, 3, 4]);
    });

    test('фильтр по автору оставляет только его посты', () {
      expect(ids(filterPosts(posts, userId: 1)), [2, 3]);
    });

    test('поиск по заголовку не зависит от регистра', () {
      expect(ids(filterPosts(posts, query: 'flutter')), [2, 3]);
      expect(ids(filterPosts(posts, query: 'FlUtTeR')), [2, 3]);
    });

    test('пробелы вокруг поискового запроса игнорируются', () {
      expect(ids(filterPosts(posts, query: '   dart  ')), [1]);
    });

    test('фильтр по автору и поиск работают вместе', () {
      expect(ids(filterPosts(posts, userId: 1, query: 'hello')), [3]);
    });

    test('сортировка по убыванию id', () {
      expect(ids(filterPosts(posts, ascending: false)), [4, 3, 2, 1]);
    });

    test('ничего не найдено — пустой список, а не ошибка', () {
      expect(filterPosts(posts, query: 'kotlin'), isEmpty);
      expect(filterPosts(posts, userId: 99), isEmpty);
      expect(filterPosts(const []), isEmpty);
    });

    test('исходный список не изменяется', () {
      filterPosts(posts, ascending: false);
      expect(ids(posts), [3, 1, 2, 4]);
    });
  });
}
