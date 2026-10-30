// СРС 9 — Widget Test: главный экран «Post Explorer» (PostsScreen).
//
// Проверяем: отображение экрана и заголовка, основные элементы,
// кнопки, реакцию на нажатия и изменение интерфейса после действий.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_post_api.dart';
import 'test_app.dart';

void main() {
  testWidgets('Экран списка: заголовок, поиск, фильтр, кнопки и посты',
      (tester) async {
    await pumpPostExplorer(tester, FakePostApi());

    // Заголовок в AppBar
    expect(find.widgetWithText(AppBar, 'Post Explorer'), findsOneWidget);

    // Поле поиска и подсказка под ним
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Поиск по заголовку'), findsOneWidget);
    expect(find.text('Ищем только среди загруженных постов: 10'),
        findsOneWidget);

    // Фильтр по автору
    expect(find.text('Автор: '), findsOneWidget);
    expect(find.text('Все посты'), findsOneWidget);

    // Кнопки
    expect(find.byTooltip('Сортировка по ID'), findsOneWidget);
    expect(find.byTooltip('Сбросить фильтры'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Посты загружены, индикатора загрузки нет
    expect(find.text('Post number 1'), findsOneWidget);
    expect(find.text('Flutter is great'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Поиск фильтрует список, «Сбросить фильтры» возвращает его',
      (tester) async {
    await pumpPostExplorer(tester, FakePostApi());

    // 1) Ищем «flutter» — остаётся один пост
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump();
    expect(find.text('Flutter is great'), findsOneWidget);
    expect(find.text('Post number 1'), findsNothing);

    // 2) Запрос без результатов — сообщение «ничего не найдено»
    await tester.enterText(find.byType(TextField), 'kotlin');
    await tester.pump();
    expect(find.text('Среди загруженных постов ничего не найдено'),
        findsOneWidget);

    // 3) Сброс фильтров: поле очищено, посты вернулись
    await tester.tap(find.byTooltip('Сбросить фильтры'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.text('Post number 1'), findsOneWidget);
    expect(find.text('Среди загруженных постов ничего не найдено'),
        findsNothing);
  });

  testWidgets('Кнопка сортировки меняет иконку и порядок постов',
      (tester) async {
    await pumpPostExplorer(tester, FakePostApi());

    double top(String text) => tester.getTopLeft(find.text(text)).dy;

    // По возрастанию: пост 1 выше поста 2
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(top('Post number 1'), lessThan(top('Post number 2')));

    await tester.tap(find.byTooltip('Сортировка по ID'));
    await tester.pump();

    // По убыванию: иконка сменилась, пост 10 теперь выше поста 9
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(top('Post number 10'), lessThan(top('Post number 9')));
  });

  testWidgets('Выбор автора в фильтре показывает только его посты',
      (tester) async {
    await pumpPostExplorer(tester, ThreeAuthorsApi());

    await selectDropdownItem(
        tester, find.byType(DropdownButton<int?>), '2. Ervin');

    // Посты 11–20 принадлежат автору 2
    expect(find.text('Post number 11'), findsOneWidget);
    expect(find.text('Post number 1'), findsNothing);
    expect(find.text('Автор #2'), findsWidgets);
    expect(find.text('Автор #1'), findsNothing);
  });

  testWidgets('Нет интернета: экран ошибки, затем «Повторить» загружает посты',
      (tester) async {
    final api = FakePostApi()
      ..error = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    await pumpPostExplorer(tester, api);

    // Состояние Error: иконка, понятный текст, кнопка, кнопка перезагрузки авторов
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Нет подключения к интернету.'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.byTooltip('Авторы не загружены. Повторить'), findsOneWidget);
    expect(find.text('Post number 1'), findsNothing);

    // Интернет появился — нажимаем «Повторить»
    api.error = null;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Нет подключения к интернету.'), findsNothing);
    expect(find.text('Post number 1'), findsOneWidget);

    // И авторов тоже можно перезагрузить — кнопка исчезает
    await tester.tap(find.byTooltip('Авторы не загружены. Повторить'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Авторы не загружены. Повторить'), findsNothing);
  });
}
