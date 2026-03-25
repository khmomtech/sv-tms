import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:easy_localization/easy_localization.dart';
import 'article_detail_screen.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _loadArticles() async {
    final raw = await rootBundle.loadString('assets/data/articles.json');
    final list = json.decode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('articles'.tr())),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadArticles(),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('error'.tr()));
          }
          final articles = snap.data ?? [];
          if (articles.isEmpty) {
            return Center(
                child: Text('no_articles'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            itemBuilder: (ctx, i) {
              final a = articles[i];
              final title =
                  a['title'] as String? ?? 'article_${i + 1}_title'.tr();
              final summary =
                  a['summary'] as String? ?? 'article_${i + 1}_summary'.tr();
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(summary),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withAlpha(153)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleDetailScreen(article: a),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
