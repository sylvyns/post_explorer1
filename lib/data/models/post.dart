import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart'; // файл сгенерирует build_runner

@JsonSerializable()
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  /// Пометка «создан локально». Сервер это поле не присылает,
  /// поэтому оно не участвует в JSON (ни в fromJson, ни в toJson).
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isLocal;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isLocal = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);

  /// Копия поста с пометкой «создан локально».
  Post asLocal() =>
      Post(id: id, userId: userId, title: title, body: body, isLocal: true);
}
