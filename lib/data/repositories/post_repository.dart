import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../remote/post_api.dart';


class PostRepository {
  static const int pageSize = 10;

  final PostApi _api;
  final PostCache _cache;

  PostRepository(this._api, this._cache);

  /// Загрузить страницу постов с сервера.
  /// userId == null — все посты, иначе — посты автора.
  /// Первая страница после успешной загрузки сохраняется в кэш.
  Future<List<Post>> fetchPosts({required int page, int? userId}) {
    return _safeCall(() async {
      final posts = userId == null
          ? await _api.getPosts(page, pageSize)
          : await _api.getPostsByUser(userId, page, pageSize);
      if (page == 1) await _cache.savePosts(userId, posts);
      return posts;
    });
  }

  /// Сохранённые посты (или null, если кэша нет).
  Future<List<Post>?> getCachedPosts(int? userId) => _cache.loadPosts(userId);

  Future<Post> getPost(int id) => _safeCall(() => _api.getPost(id));

  Future<List<Comment>> getComments(int postId) =>
      _safeCall(() => _api.getComments(postId));

  Future<User> getUser(int id) => _safeCall(() => _api.getUser(id));

  /// Авторы: с сервера, а при ошибке — из кэша.
  Future<List<User>> getUsers() async {
    try {
      final users = await _safeCall(() => _api.getUsers());
      await _cache.saveUsers(users);
      return users;
    } on AppException {
      final cached = await _cache.loadUsers();
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Создать пост. JSONPlaceholder его НЕ сохраняет навсегда,
  /// поэтому возвращаем пост с пометкой isLocal = true.
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) {
    return _safeCall(() async {
      final created = await _api.createPost({
        'title': title,
        'body': body,
        'userId': userId,
      });
      return created.asLocal();
    });
  }

  /// Выполняет запрос и превращает любую ошибку в AppException.
  Future<T> _safeCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, st) {
      throw AppException.from(e, st);
    }
  }
}
