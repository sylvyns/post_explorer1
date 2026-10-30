// СРС 9 — Unit Test: валидация формы «Новый пост».
//
// Функции validateTitle / validateBody — это логика экрана CreatePostScreen.
// Они возвращают текст ошибки или null, если ошибки нет.
// Здесь проверяются граничные значения и некорректный ввод.

import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/presentation/screens/create_post_screen.dart';

void main() {
  group('validateTitle — заголовок 5–100 символов', () {
    test('корректный заголовок проходит проверку', () {
      expect(validateTitle('Мой первый пост'), isNull);
    });

    test('пустое значение, null и одни пробелы — ошибка «Введите заголовок»',
        () {
      expect(validateTitle(null), 'Введите заголовок');
      expect(validateTitle(''), 'Введите заголовок');
      expect(validateTitle('     '), 'Введите заголовок');
    });

    test('граница снизу: 4 символа — ошибка, 5 символов — ок', () {
      expect(validateTitle('abcd'), 'Минимум 5 символов');
      expect(validateTitle('abcde'), isNull);
    });

    test('граница сверху: 100 символов — ок, 101 — ошибка', () {
      expect(validateTitle('a' * 100), isNull);
      expect(validateTitle('a' * 101), 'Максимум 100 символов');
    });

    test('пробелы по краям не считаются символами', () {
      // После trim() остаётся 4 символа — это меньше минимума.
      expect(validateTitle('   abcd   '), 'Минимум 5 символов');
    });
  });

  group('validateBody — текст 10–1000 символов', () {
    test('корректный текст проходит проверку', () {
      expect(validateBody('Это достаточно длинный текст поста'), isNull);
    });

    test('пустой текст — ошибка «Введите текст поста»', () {
      expect(validateBody(null), 'Введите текст поста');
      expect(validateBody(''), 'Введите текст поста');
      expect(validateBody('\n\n   '), 'Введите текст поста');
    });

    test('граница снизу: 9 символов — ошибка, 10 — ок', () {
      expect(validateBody('123456789'), 'Минимум 10 символов');
      expect(validateBody('1234567890'), isNull);
    });

    test('граница сверху: 1000 символов — ок, 1001 — ошибка', () {
      expect(validateBody('x' * 1000), isNull);
      expect(validateBody('x' * 1001), 'Максимум 1000 символов');
    });
  });
}
