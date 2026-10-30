import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

part 'post_api.g.dart'; 

/// Описание всех запросов к JSONPlaceholder.
/// Мы только пишем «что вызвать», код запросов генерирует Retrofit.
@RestApi()
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl}) = _PostApi;

  // 1. GET /posts?_page=1&_limit=10 — список с пагинацией
  @GET('/posts')
  Future<List<Post>> getPosts(
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  // 2. GET /posts/{id} — один пост
  @GET('/posts/{id}')
  Future<Post> getPost(@Path('id') int id);

  // 3. GET /posts?userId={id} — посты автора (тоже с пагинацией)
  @GET('/posts')
  Future<List<Post>> getPostsByUser(
    @Query('userId') int userId,
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  // 4. GET /posts/{id}/comments — комментарии к посту
  @GET('/posts/{id}/comments')
  Future<List<Comment>> getComments(@Path('id') int postId);

  // 5. POST /posts — создать пост
  @POST('/posts')
  Future<Post> createPost(@Body() Map<String, dynamic> body);

  // Дополнительно: авторы
  @GET('/users')
  Future<List<User>> getUsers();

  @GET('/users/{id}')
  Future<User> getUser(@Path('id') int id);
}
