import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../models/user.dart';

/// Простой локальный кэш на SharedPreferences.
/// Списки хранятся как JSON-строка.

class PostCache {
  String _postsKey(int? userId) =>
      userId == null ? 'posts_all' : 'posts_user_$userId';

  static const _usersKey = 'users';

  Future<void> savePosts(int? userId, List<Post> posts) =>
      _saveList(_postsKey(userId), posts.map((p) => p.toJson()).toList());

  Future<List<Post>?> loadPosts(int? userId) =>
      _loadList(_postsKey(userId), Post.fromJson);

  Future<void> saveUsers(List<User> users) =>
      _saveList(_usersKey, users.map((u) => u.toJson()).toList());

  Future<List<User>?> loadUsers() => _loadList(_usersKey, User.fromJson);

 

  Future<void> _saveList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  /// Возвращает null, если кэша нет или он испорчен (приложение не падает).
  Future<List<T>?> _loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
