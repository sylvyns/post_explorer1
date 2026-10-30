// СРС 9 — Widget Test: переходы между экранами и взаимодействие экранов.
//
// Запускается всё приложение целиком (PostExplorerApp), как в main().

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/presentation/screens/create_post_screen.dart';
import 'package:post_explorer/presentation/screens/post_detail_screen.dart';
import 'package:post_explorer/presentation/screens/posts_screen.dart';

import '../fake_post_api.dart';
import 'test_app.dart';

void main() {
  testWidgets('Нажатие на пост открывает экран деталей, «Назад» возвращает',
      (tester) async {
    await pumpPostExplorer(tester, FakePostApi());

    await tester.tap(find.text('Post number 1'));
    await tester.pumpAndSettle(); // анимация перехода + загрузка деталей

    // Экран деталей: заголовок, текст, автор и комментарии
    expect(find.byType(PostDetailScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Пост #1'), findsOneWidget);
    expect(find.text('Post number 1'), findsOneWidget);
    expect(find.text('Body 1'), findsOneWidget);
    expect(find.text('Автор: Leanne (нет email)'), findsOneWidget);
    expect(find.text('Комментарии'), findsOneWidget);
    expect(find.text('Hi'), findsOneWidget);
    expect(find.textContaining('Nice post'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailScreen), findsNothing);
    expect(find.widgetWithText(AppBar, 'Post Explorer'), findsOneWidget);
  });

  testWidgets('Кнопка «+» открывает форму, созданный пост появляется в списке',
      (tester) async {
    await pumpPostExplorer(tester, FakePostApi());

    // 1) Переход на экран создания
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(CreatePostScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Новый пост'), findsOneWidget);

    // 2) Заполняем форму и отправляем
    await tester.enterText(find.byType(TextFormField).at(0), 'Пост из теста');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Текст поста из widget-теста');
    await selectDropdownItem(
        tester, find.byType(DropdownButton<int>), '1. Leanne');
    await tester.tap(find.widgetWithText(FilledButton, 'Отправить'));
    await tester.pumpAndSettle();
    expect(find.text('id: 101'), findsOneWidget);

    // 3) Возвращаемся к списку — новый пост вверху с пометкой
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(PostsScreen), findsOneWidget);
    expect(find.text('Пост из теста'), findsOneWidget);
    expect(find.text('создан локально'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Пост из теста')).dy,
      lessThan(tester.getTopLeft(find.text('Post number 1')).dy),
    );

    // 4) Открываем локальный пост — запросов к серверу нет, есть пояснение
    await tester.tap(find.text('Пост из теста'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Пост #101'), findsOneWidget);
    expect(find.textContaining('Пост создан локально'), findsOneWidget);
  });
}
