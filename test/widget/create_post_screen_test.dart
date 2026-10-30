// СРС 9 — Widget Test: экран «Новый пост» (CreatePostScreen).
//
// Проверяем форму: поля, кнопку, сообщения об ошибках при неверном вводе,
// успешную отправку и ошибку сервера.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/presentation/screens/create_post_screen.dart';
import 'package:post_explorer/presentation/state/posts_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_post_api.dart';
import 'test_app.dart';

/// Открывает только экран CreatePostScreen (с уже загруженными авторами).
Future<PostsProvider> pumpCreateScreen(
    WidgetTester tester, FakePostApi api) async {
  SharedPreferences.setMockInitialValues({});
  useTallScreen(tester);
  final repository = PostRepository(api, PostCache());
  final postsProvider = PostsProvider(repository);
  await postsProvider.loadUsers();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<PostRepository>.value(value: repository),
        ChangeNotifierProvider.value(value: postsProvider),
      ],
      child: const MaterialApp(home: CreatePostScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return postsProvider;
}

Finder get titleField => find.byType(TextFormField).at(0);
Finder get bodyField => find.byType(TextFormField).at(1);
Finder get sendButton => find.widgetWithText(FilledButton, 'Отправить');

void main() {
  testWidgets('Форма отображает заголовок, поля, выбор автора и кнопку',
      (tester) async {
    await pumpCreateScreen(tester, FakePostApi());

    expect(find.widgetWithText(AppBar, 'Новый пост'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Заголовок (5–100 символов)'), findsOneWidget);
    expect(find.text('Текст (10–1000 символов)'), findsOneWidget);
    expect(find.byType(DropdownButton<int>), findsOneWidget);
    expect(find.text('Выберите автора'), findsOneWidget); // подсказка списка
    expect(sendButton, findsOneWidget);

    // Кнопка активна (onPressed != null)
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);
  });

  testWidgets('Пустая форма: появляются ошибки, запрос не отправляется',
      (tester) async {
    await pumpCreateScreen(tester, FakePostApi());

    await tester.tap(sendButton);
    await tester.pump();

    expect(find.text('Введите заголовок'), findsOneWidget);
    expect(find.text('Введите текст поста'), findsOneWidget);
    // «Выберите автора» теперь дважды: подсказка списка + красная ошибка
    expect(find.text('Выберите автора'), findsNWidgets(2));
    expect(find.text('Ответ сервера:'), findsNothing);
  });

  testWidgets('Слишком короткий ввод: ошибки про минимальную длину',
      (tester) async {
    await pumpCreateScreen(tester, FakePostApi());

    await tester.enterText(titleField, 'abc');
    await tester.enterText(bodyField, 'short');
    await tester.tap(sendButton);
    await tester.pump();

    expect(find.text('Минимум 5 символов'), findsOneWidget);
    expect(find.text('Минимум 10 символов'), findsOneWidget);
    expect(find.text('Ответ сервера:'), findsNothing);
  });

  testWidgets('Корректная форма: показывается ответ сервера, поля очищаются',
      (tester) async {
    final provider = await pumpCreateScreen(tester, FakePostApi());

    await tester.enterText(titleField, 'Мой тестовый пост');
    await tester.enterText(bodyField, 'Текст тестового поста');
    await selectDropdownItem(
        tester, find.byType(DropdownButton<int>), '1. Leanne');
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // Карточка с ответом сервера
    expect(find.text('Ответ сервера:'), findsOneWidget);
    expect(find.text('id: 101'), findsOneWidget);
    expect(find.text('userId: 1'), findsOneWidget);
    expect(find.text('title: Мой тестовый пост'), findsOneWidget);
    expect(find.text('создан локально'), findsOneWidget);

    // Поля очищены, ошибок нет
    expect(tester.widget<TextFormField>(titleField).controller!.text, isEmpty);
    expect(find.text('Введите заголовок'), findsNothing);

    // Пост попал в общий список с пометкой isLocal
    expect(provider.visiblePosts.first.title, 'Мой тестовый пост');
    expect(provider.visiblePosts.first.isLocal, isTrue);
  });

  testWidgets('Ошибка сервера: показывается текст ошибки, кнопка снова активна',
      (tester) async {
    final api = FakePostApi();
    await pumpCreateScreen(tester, api);

    final options = RequestOptions(path: '/posts');
    api.error = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: options, statusCode: 500),
    );

    await tester.enterText(titleField, 'Мой тестовый пост');
    await tester.enterText(bodyField, 'Текст тестового поста');
    await selectDropdownItem(
        tester, find.byType(DropdownButton<int>), '1. Leanne');
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('Сервер временно недоступен (код 500).'), findsOneWidget);
    expect(find.text('Ответ сервера:'), findsNothing);
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);
    // Введённый текст не потерян
    expect(find.text('Мой тестовый пост'), findsOneWidget);
  });
}
