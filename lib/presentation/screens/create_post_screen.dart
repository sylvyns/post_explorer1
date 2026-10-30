import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/posts_provider.dart';
import '../widgets/post_tile.dart';

// ---- Валидация (отдельные функции — их легко объяснить и протестировать) ----

String? validateTitle(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Введите заголовок';
  if (text.length < 5) return 'Минимум 5 символов';
  if (text.length > 100) return 'Максимум 100 символов';
  return null; // null = ошибок нет
}

String? validateBody(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Введите текст поста';
  if (text.length < 10) return 'Минимум 10 символов';
  if (text.length > 1000) return 'Максимум 1000 символов';
  return null;
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  int? _userId;
  String? _userError;

  // Своё состояние формы — не связано с загрузкой списка.
  bool _isSending = false;
  String? _sendError;
  Post? _createdPost;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSending) return; // защита от повторного нажатия

    // 1) Проверяем данные ДО отправки
    final formOk = _formKey.currentState!.validate();
    setState(() => _userError = _userId == null ? 'Выберите автора' : null);
    if (!formOk || _userId == null) return;

    final repository = context.read<PostRepository>();
    final postsProvider = context.read<PostsProvider>();

    setState(() {
      _isSending = true;
      _sendError = null;
      _createdPost = null;
    });

    // 2) Отправляем POST
    try {
      final post = await repository.createPost(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        userId: _userId!,
      );
      postsProvider.addLocalPost(post); // добавляем в список с пометкой
      if (!mounted) return;
      setState(() => _createdPost = post);
      _titleController.clear();
      _bodyController.clear();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _sendError = e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final users = postsProvider.users;

    return Scaffold(
      appBar: AppBar(title: const Text('Новый пост')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              enabled: !_isSending,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Заголовок (5–100 символов)',
                border: OutlineInputBorder(),
              ),
              validator: validateTitle,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              enabled: !_isSending,
              maxLength: 1000,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Текст (10–1000 символов)',
                border: OutlineInputBorder(),
              ),
              validator: validateBody,
            ),
            const SizedBox(height: 12),

            // Выбор автора из списка пользователей (GET /users)
            if (users.isEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(postsProvider.usersLoading
                        ? 'Загружаем авторов…'
                        : 'Авторы не загружены'),
                  ),
                  TextButton(
                    onPressed:
                        postsProvider.usersLoading ? null : postsProvider.loadUsers,
                    child: const Text('Загрузить'),
                  ),
                ],
              )
            else
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Выберите автора'),
                value: _userId,
                items: users
                    .map((u) => DropdownMenuItem<int>(
                          value: u.id,
                          child: Text('${u.id}. ${u.name}'),
                        ))
                    .toList(),
                onChanged:
                    _isSending ? null : (v) => setState(() => _userId = v),
              ),
            if (_userError != null)
              Text(_userError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),

            // Кнопка блокируется, пока идёт запрос
            FilledButton(
              onPressed: _isSending ? null : _submit,
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Отправить'),
            ),

            if (_sendError != null) ...[
              const SizedBox(height: 12),
              Text(_sendError!, style: const TextStyle(color: Colors.red)),
            ],

            if (_createdPost != null) ...[
              const SizedBox(height: 16),
              _buildResult(_createdPost!),
            ],
          ],
        ),
      ),
    );
  }

  /// Показываем объект, который вернул сервер.
  Widget _buildResult(Post post) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.black87),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ответ сервера:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('id: ${post.id}'),
              Text('userId: ${post.userId}'),
              Text('title: ${post.title}'),
              Text('body: ${post.body}'),
              const LocalBadge(),
              const SizedBox(height: 8),
              const Text(
                'JSONPlaceholder только имитирует создание и не хранит пост. '
                'Поэтому пост добавлен в список локально.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
