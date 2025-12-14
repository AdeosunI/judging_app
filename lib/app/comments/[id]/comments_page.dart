import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:judging_app/helpers/firestore_collections.dart';
import 'package:judging_app/helpers/types.dart';
import 'package:routefly/routefly.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  final _db = FirebaseFirestore.instance;

  bool _isLoading = true;
  Map<String, List<Comment>> _commentsByUser = const {};
  String? _eventName;

  String? _eventIdFromRoute() {
    final q = Routefly.query['id'];
    if (q != null && q.isNotEmpty) return q;

    final segs = Routefly.currentUri.pathSegments;
    final i = segs.indexOf('comments');
    if (i >= 0 && i + 1 < segs.length) return segs[i + 1];

    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isLoading) {
      _fetchComments();
    }
  }

  Future<void> _fetchComments() async {
    final id = _eventIdFromRoute();
    if (id == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _commentsByUser = const {};
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await _db.collection(eventsCollection).doc(id).get();
      if (!doc.exists) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _commentsByUser = const {};
        });
        return;
      }

      final data = doc.data();
      _eventName = data?['eventName'] as String?;
      final raw = (data?['comments'] as Map<String, dynamic>?) ?? {};

      final parsed = <String, List<Comment>>{};
      for (final entry in raw.entries) {
        final user = entry.key;
        final list = (entry.value as List<dynamic>?) ?? const [];

        parsed[user] = list
            .map((e) => Comment.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _commentsByUser = parsed;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _commentsByUser = const {};
      });
    }
  }

  String _formatTimestamp(BuildContext context, Timestamp timestamp) {
    final dt = timestamp.toDate().toLocal();
    final date = MaterialLocalizations.of(context).formatFullDate(dt);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(dt), alwaysUse24HourFormat: false);
    return '$date at $time';
  }

  List<_FlattenedComment> _flattenAndSort(Map<String, List<Comment>> comments) {
    final all = <_FlattenedComment>[];

    for (final entry in comments.entries) {
      final user = entry.key;
      for (final c in entry.value) {
        all.add(_FlattenedComment(user: user, comment: c));
      }
    }

    all.sort((a, b) {
      final ad = a.comment.date.toDate().millisecondsSinceEpoch;
      final bd = b.comment.date.toDate().millisecondsSinceEpoch;
      return bd.compareTo(ad);
    });

    return all;
  }

  @override
  Widget build(BuildContext context) {
    final allComments = _flattenAndSort(_commentsByUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading
              ? ""
              : _eventName == null
              ? 'Comments'
              : 'Comments on $_eventName',
        ),
      ),
      body: _isLoading
          ? const SizedBox.shrink()
          : Container(
              color: const Color(0xFFF2F2F2),
              padding: const EdgeInsets.all(16),
              child: allComments.isEmpty
                  ? const Center(
                      child: Text(
                        'No comments available for this event.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: allComments.length,
                      itemBuilder: (context, index) {
                        final item = allComments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTimestamp(context, item.comment.date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF333333),
                                    height: 22 / 16,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: item.user,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                    const TextSpan(text: ' posted: "'),
                                    TextSpan(text: item.comment.comment),
                                    const TextSpan(text: '"'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _FlattenedComment {
  final String user;
  final Comment comment;

  const _FlattenedComment({required this.user, required this.comment});
}
