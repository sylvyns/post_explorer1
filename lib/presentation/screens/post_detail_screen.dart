import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../widgets/post_tile.dart';
import '../widgets/state_views.dart';

/// Экран деталей: пост (GET /posts/{id}), автор (GET /users/{id})
/// и комментарии (GET /posts/{id}/comments).
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post = widget.post; // сразу показываем то, что уже есть
  User? _author;
  List<Comment> _comments = [];
  late bool _isLoading = !widget.post.isLocal;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Локальный пост на сервере не существует — запросы не отправляем.
    if (!widget.post.isLocal) _load();
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _load() async {
    final repository = context.read<PostRepository>();
    try {
      final post = await repository.getPost(widget.post.id);
      final comments = await repository.getComments(widget.post.id);
      User? author;
      try {
        author = await repository.getUser(post.userId);
      } on AppException {
        author = null; // автор — не главное, без него экран тоже работает
      }
      if (!mounted) return;
      setState(() {
        _post = post;
        _comments = comments;
        _author = author;
        _isLoading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Пост #${_post.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_post.title, style: Theme.of(context).textTheme.titleLarge),
          if (_post.isLocal) const LocalBadge(),
          const SizedBox(height: 12),
          Text(_post.body),
          const SizedBox(height: 12),
          Text(
            _author != null
                ? 'Автор: ${_author!.name} (${_author!.email ?? 'нет email'})'
                : 'Автор #${_post.userId}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const Divider(height: 32),
          Text('Комментарии', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._buildComments(),
        ],
      ),
    );
  }

  List<Widget> _buildComments() {
    if (_post.isLocal) {
      return const [
        Text('Пост создан локально. JSONPlaceholder не сохраняет новые посты, '
            'поэтому на сервере его нет и комментариев тоже нет.'),
      ];
    }
    if (_isLoading) {
      return const [Center(child: CircularProgressIndicator())];
    }
    if (_error != null) {
      return [ErrorView(message: _error!, onRetry: _retry)];
    }
    if (_comments.isEmpty) {
      return const [EmptyView(message: 'Комментариев нет')];
    }
    return _comments
        .map((c) => Card(
              child: ListTile(
                title: Text(c.name),
                subtitle: Text('${c.email ?? ''}\n${c.body}'),
                isThreeLine: true,
              ),
            ))
        .toList();
  }
}
