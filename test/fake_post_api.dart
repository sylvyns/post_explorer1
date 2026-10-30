import 'dart:math';

import 'package:post_explorer/data/models/comment.dart';
import 'package:post_explorer/data/models/post.dart';
import 'package:post_explorer/data/models/user.dart';
import 'package:post_explorer/data/remote/post_api.dart';

/// Поддельный API для тестов — без интернета.
/// 30 постов: 1–10 у автора 1, 11–20 у автора 2, 21–30 у автора 3.
class FakePostApi implements PostApi {
  final List<Post> allPosts = List.generate(
    30,
    (i) => Post(
      id: i + 1,
      userId: i ~/ 10 + 1,
      title: i == 4 ? 'Flutter is great' : 'Post number ${i + 1}',
      body: 'Body ${i + 1}',
    ),
  );

  /// Если задать ошибку — каждый запрос будет её выбрасывать.
  Object? error;

  /// Сколько раз запрашивали каждую страницу.
  final Map<int, int> pageCalls = {};

  List<Post> _page(List<Post> source, int page, int limit) {
    final start = (page - 1) * limit;
    if (start >= source.length) return [];
    return source.sublist(start, min(start + limit, source.length));
  }

  @override
  Future<List<Post>> getPosts(int page, int limit) async {
    pageCalls[page] = (pageCalls[page] ?? 0) + 1;
    if (error != null) throw error!;
    return _page(allPosts, page, limit);
  }

  @override
  Future<List<Post>> getPostsByUser(int userId, int page, int limit) async {
    pageCalls[page] = (pageCalls[page] ?? 0) + 1;
    if (error != null) throw error!;
    return _page(allPosts.where((p) => p.userId == userId).toList(), page, limit);
  }

  @override
  Future<Post> getPost(int id) async {
    if (error != null) throw error!;
    return allPosts.firstWhere((p) => p.id == id);
  }

  @override
  Future<List<Comment>> getComments(int postId) async {
    if (error != null) throw error!;
    return [Comment(id: 1, postId: postId, name: 'Hi', body: 'Nice post')];
  }

  @override
  Future<Post> createPost(Map<String, dynamic> body) async {
    if (error != null) throw error!;
    return Post(
      id: 101,
      userId: body['userId'] as int,
      title: body['title'] as String,
      body: body['body'] as String,
    );
  }

  @override
  Future<List<User>> getUsers() async {
    if (error != null) throw error!;
    return const [User(id: 1, name: 'Leanne', username: 'Bret')];
  }

  @override
  Future<User> getUser(int id) async {
    if (error != null) throw error!;
    return User(id: id, name: 'Leanne', username: 'Bret');
  }
}
