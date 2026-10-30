import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/posts_provider.dart';
import '../widgets/post_tile.dart';
import '../widgets/state_views.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  /// Когда до конца списка осталось < 200 px — грузим следующую страницу.
  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<PostsProvider>().loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          IconButton(
            tooltip: 'Сортировка по ID',
            icon: Icon(provider.sortAscending
                ? Icons.arrow_upward
                : Icons.arrow_downward),
            onPressed: provider.toggleSort,
          ),
          IconButton(
            tooltip: 'Сбросить фильтры',
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () {
              _searchController.clear();
              provider.resetFilters();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(provider),
          if (provider.status == ListStatus.cached)
            CachedBanner(
              text: provider.isLoadingFirst
                  ? 'Показаны сохранённые данные. Обновляем…'
                  : 'Показаны сохранённые данные. ${provider.errorMessage ?? ''}',
            ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildFilters(PostsProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          // Поиск по заголовку (локально, среди загруженных)
          TextField(
            controller: _searchController,
            onChanged: provider.setSearch,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Поиск по заголовку',
              helperText:
                  'Ищем только среди загруженных постов: ${provider.loadedCount}',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          // Фильтр по автору: «Все посты» или конкретный автор
          Row(
            children: [
              const Text('Автор: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: provider.selectedUserId,
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('Все посты')),
                    ...provider.users.map((u) => DropdownMenuItem<int?>(
                          value: u.id,
                          child: Text('${u.id}. ${u.name}'),
                        )),
                  ],
                  onChanged: provider.setUserFilter,
                ),
              ),
              if (provider.usersError != null)
                IconButton(
                  tooltip: 'Авторы не загружены. Повторить',
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.loadUsers,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PostsProvider provider) {
    // Loading — первичная загрузка, показывать пока нечего
    if (provider.status == ListStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Error — ошибка и нет сохранённых данных
    if (provider.status == ListStatus.error) {
      return ErrorView(
        message: provider.errorMessage ?? 'Ошибка',
        onRetry: provider.loadFirstPage,
      );
    }

    final posts = provider.visiblePosts;

    return RefreshIndicator(
      onRefresh: provider.loadFirstPage, // pull-to-refresh
      child: posts.isEmpty
          // Empty — постов нет или поиск ничего не нашёл
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyView(
                  message: provider.searchQuery.isEmpty
                      ? 'Постов нет'
                      : 'Среди загруженных постов ничего не найдено',
                ),
              ],
            )
          // Success / Cached — список + футер
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == posts.length) return _buildFooter(provider);
                final post = posts[index];
                return PostTile(
                  post: post,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post)),
                  ),
                );
              },
            ),
    );
  }

  /// Низ списка: индикатор подгрузки / ошибка с кнопкой / «больше нет».
  Widget _buildFooter(PostsProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(provider.loadMoreError!, textAlign: TextAlign.center),
            TextButton(
              onPressed: provider.retryNextPage,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (!provider.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Больше постов нет')),
      );
    }
    return const SizedBox(height: 80);
  }
}
