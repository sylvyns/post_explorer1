import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/presentation/widgets/post_tile.dart';

void main() {
  testWidgets('Локальный пост показывается с пометкой «создан локально»',
      (tester) async {
    const post =
        Post(id: 101, userId: 1, title: 'Мой пост', body: 'Текст', isLocal: true);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PostTile(post: post, onTap: () {})),
    ));

    expect(find.text('Мой пост'), findsOneWidget);
    expect(find.text('создан локально'), findsOneWidget);
  });
}
