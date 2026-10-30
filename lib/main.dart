import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/posts_screen.dart';
import 'presentation/state/posts_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Собираем слои снизу вверх:
  // Dio -> Retrofit API -> Repository (+ кэш) -> Provider -> UI
  final api = PostApi(DioClient.instance);
  final repository = PostRepository(api, PostCache());

  runApp(
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
}

class PostExplorerApp extends StatelessWidget {
  const PostExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const PostsScreen(),
    );
  }
}
