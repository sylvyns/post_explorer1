import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

/// Состояния экрана списка.
enum ListStatus {
  loading, // первичная загрузка, показывать нечего
  success, // данные с сервера
  cached, // показаны сохранённые данные (сервер недоступен или идёт обновление)
  error, // ошибка и показывать нечего
  empty, // сервер вернул пустой список
}

/// Фильтрация и сортировка — отдельная чистая функция, её легко тестировать.
/// Поиск идёт ТОЛЬКО по уже загруженным постам.
List<Post> filterPosts(
  List<Post> posts, {
  int? userId,
  String query = '',
  bool ascending = true,
}) {
  final q = query.trim().toLowerCase();
  final result = posts.where((p) {
    final byUser = userId == null || p.userId == userId;
    final byTitle = q.isEmpty || p.title.toLowerCase().contains(q);
    return byUser && byTitle;
  }).toList();
  result.sort((a, b) => ascending ? a.id.compareTo(b.id) : b.id.compareTo(a.id));
  return result;
}

class PostsProvider extends ChangeNotifier {
  PostsProvider(this._repository);

  final PostRepository _repository;

  // ---- данные ----
  List<Post> _posts = []; // посты с сервера (или из кэша)
  final List<Post> _localPosts = []; // созданные через форму
  int _page = 0; // сколько страниц загружено
  bool hasMore = true;

  // ---- состояния (отдельно для разных операций, а не один isLoading) ----
  ListStatus status = ListStatus.loading;
  String? errorMessage;
  bool isLoadingFirst = false; // загрузка/обновление первой страницы
  bool isLoadingMore = false; // подгрузка следующей страницы
  String? loadMoreError; // ошибка подгрузки следующей страницы

  /// Номер «текущего» запроса. Если пользователь сменил фильтр,
  /// ответы старых запросов игнорируются — результаты не смешиваются.
  int _requestId = 0;

  // ---- фильтры ----
  int? selectedUserId;
  String searchQuery = '';
  bool sortAscending = true;

  // ---- авторы ----
  List<User> users = [];
  bool usersLoading = false;
  String? usersError;

  int get loadedCount => _posts.length;

  /// То, что видит пользователь: локальные посты сверху, затем серверные.
  List<Post> get visiblePosts => [
        ...filterPosts(_localPosts,
            userId: selectedUserId, query: searchQuery, ascending: sortAscending),
        ...filterPosts(_posts,
            userId: selectedUserId, query: searchQuery, ascending: sortAscending),
      ];

  /// Первая страница: сначала кэш, потом сервер.
  /// Используется и при старте, и для pull-to-refresh.
  Future<void> loadFirstPage() async {
    final requestId = ++_requestId;
    isLoadingFirst = true;
    isLoadingMore = false;
    loadMoreError = null;
    errorMessage = null;

    // 1) Показываем кэш, если на экране пока пусто.
    final cached = await _repository.getCachedPosts(selectedUserId);
    if (requestId != _requestId) return; // запрос устарел
    if (_posts.isEmpty && cached != null && cached.isNotEmpty) {
      _posts = [...cached];
      _page = 1;
      hasMore = true;
      status = ListStatus.cached;
    } else if (_posts.isEmpty) {
      status = ListStatus.loading;
    }
    notifyListeners();

    // 2) Запрашиваем свежие данные.
    try {
      final fresh =
          await _repository.fetchPosts(page: 1, userId: selectedUserId);
      if (requestId != _requestId) return;
      _posts = [...fresh];
      _page = 1;
      hasMore = fresh.length == PostRepository.pageSize;
      status = fresh.isEmpty ? ListStatus.empty : ListStatus.success;
    } on AppException catch (e) {
      if (requestId != _requestId) return;
      errorMessage = e.message;
      // Последний успешный результат НЕ удаляем.
      status = _posts.isNotEmpty ? ListStatus.cached : ListStatus.error;
    }
    isLoadingFirst = false;
    notifyListeners();
  }

  /// Следующая страница при прокрутке.
  Future<void> loadNextPage() async {
    // Защита от повторной загрузки одной и той же страницы.
    if (isLoadingFirst || isLoadingMore || !hasMore) return;
    if (loadMoreError != null || _posts.isEmpty) return;

    final requestId = _requestId;
    isLoadingMore = true;
    notifyListeners();

    try {
      final next = await _repository.fetchPosts(
          page: _page + 1, userId: selectedUserId);
      if (requestId != _requestId) return;
      final ids = _posts.map((p) => p.id).toSet();
      _posts.addAll(next.where((p) => !ids.contains(p.id))); // без дубликатов
      _page++;
      hasMore = next.length == PostRepository.pageSize;
    } on AppException catch (e) {
      if (requestId != _requestId) return;
      loadMoreError = e.message;
    }
    isLoadingMore = false;
    notifyListeners();
  }

  /// Кнопка «Повторить» внизу списка.
  Future<void> retryNextPage() {
    loadMoreError = null;
    return loadNextPage();
  }

  /// Смена автора: сбрасываем страницы и старые результаты.
  Future<void> setUserFilter(int? userId) {
    if (userId == selectedUserId) return Future.value();
    selectedUserId = userId;
    _posts = [];
    _page = 0;
    hasMore = true;
    isLoadingMore = false;
    loadMoreError = null;
    status = ListStatus.loading;
    notifyListeners();
    return loadFirstPage();
  }

  void setSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void toggleSort() {
    sortAscending = !sortAscending;
    notifyListeners();
  }

  Future<void> resetFilters() {
    searchQuery = '';
    sortAscending = true;
    if (selectedUserId != null) return setUserFilter(null);
    notifyListeners();
    return Future.value();
  }

  void addLocalPost(Post post) {
    _localPosts.insert(0, post);
    notifyListeners();
  }

  Future<void> loadUsers() async {
    usersLoading = true;
    usersError = null;
    notifyListeners();
    try {
      users = await _repository.getUsers();
    } on AppException catch (e) {
      usersError = e.message;
    }
    usersLoading = false;
    notifyListeners();
  }
}
