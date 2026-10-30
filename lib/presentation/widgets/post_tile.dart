import 'package:flutter/material.dart';

import '../../data/models/post.dart';

class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text('${post.id}')),
        title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Автор #${post.userId}'),
            if (post.isLocal) const LocalBadge(),
          ],
        ),
      ),
    );
  }
}

/// Пометка «создан локально».
class LocalBadge extends StatelessWidget {
  const LocalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'создан локально',
        style: TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }
}
