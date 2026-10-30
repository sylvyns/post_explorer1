// Вспомогательные функции для widget-тестов (сам файл тестом не является —
// flutter test запускает только файлы *_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/user.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/main.dart' show PostExplorerApp;
import 'package:post_explorer/presentation/state/posts_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_post_api.dart';

/// FakePostApi с тремя авторами (в базовом — только один).
/// Посты 1–10 у автора 1, 11–20 у автора 2, 21–30 у автора 3.
class ThreeAuthorsApi extends FakePostApi {
  @override
  Future<List<User>> getUsers() async {
    if (error != null) throw error!;
    return const [
      User(id: 1, name: 'Leanne', username: 'Bret'),
      User(id: 2, name: 'Ervin', username: 'Antonette'),
      User(id: 3, name: 'Clementine', username: 'Samantha'),
    ];
  }
}

/// Высокий экран (600×1200), чтобы все элементы формы помещались без прокрутки.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Запускает НАСТОЯЩЕЕ приложение (PostExplorerApp) так же, как main(),
/// но вместо интернета — FakePostApi, вместо SharedPreferences — память.
Future<void> pumpPostExplorer(WidgetTester tester, FakePostApi api) async {
  SharedPreferences.setMockInitialValues({});
  useTallScreen(tester);
  final repository = PostRepository(api, PostCache());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<PostRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (_) => PostsProvider(repository)
            ..loadFirstPage()
            ..loadUsers(),
        ),
      ],
      child: const PostExplorerApp(),
    ),
  );
  // Ждём, пока закончится загрузка и исчезнет индикатор.
  await tester.pumpAndSettle();
}

/// Открывает выпадающий список и выбирает пункт с текстом [item].
Future<void> selectDropdownItem(
    WidgetTester tester, Finder dropdown, String item) async {
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  // .last — пункт в открытом меню (поверх экрана)
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}
