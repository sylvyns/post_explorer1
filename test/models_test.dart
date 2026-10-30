import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/core/error/app_exception.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/models/user.dart';

void main() {
  // Тест 1
  test('JSON успешно превращается в Post', () {
    final json = {
      'userId': 1,
      'id': 7,
      'title': 'Hello',
      'body': 'World',
    };

    final post = Post.fromJson(json);

    expect(post.id, 7);
    expect(post.userId, 1);
    expect(post.title, 'Hello');
    expect(post.body, 'World');
    expect(post.isLocal, false);
  });

  // Тест 2
  test('Post превращается обратно в JSON', () {
    const post = Post(id: 3, userId: 2, title: 'T', body: 'B');

    final json = post.toJson();

    expect(json, {'id': 3, 'userId': 2, 'title': 'T', 'body': 'B'});
    expect(json.containsKey('isLocal'), false); // служебное поле не уходит в JSON
  });

  // Доп.: вложенная модель и nullable-поля
  test('User с вложенным Address, без необязательных полей', () {
    final user = User.fromJson({
      'id': 1,
      'name': 'Leanne',
      'username': 'Bret',
      'address': {'city': 'Gwenborough'},
    });

    expect(user.address?.city, 'Gwenborough');
    expect(user.phone, isNull);
    expect(user.company, isNull);
  });

  // Доп.: некорректный JSON не роняет приложение, а даёт понятную ошибку
  test('Нет обязательного поля -> AppException(parse)', () {
    final badJson = {'id': 1, 'userId': 1, 'body': 'без title'};

    AppException? caught;
    try {
      Post.fromJson(badJson);
    } catch (e) {
      caught = AppException.from(e);
    }

    expect(caught?.type, ErrorType.parse);
  });
}
