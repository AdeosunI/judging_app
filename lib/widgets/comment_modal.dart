import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:judging_app/helpers/firestore_collections.dart';
import 'package:judging_app/helpers/types.dart';

Future<bool> addComment(String eventId, String commentText) async {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  final displayName = auth.currentUser?.displayName ?? auth.currentUser!.email!;

  final eventRef = db.collection(eventsCollection).doc(eventId);

  final newComment = {'comment': commentText, 'date': Timestamp.now()};

  try {
    final eventSnapshot = await eventRef.get();
    final eventData = eventSnapshot.data();

    final Map<String, dynamic> usersComments =
        (eventData?['comments'] as Map<String, dynamic>?) ?? {};

    final List<dynamic> existingComments =
        (usersComments[displayName] as List<dynamic>?) ?? [];

    usersComments[displayName] = [...existingComments, newComment];

    await eventRef.update({'comments': usersComments});

    return true;
  } catch (error) {
    return false;
  }
}

Future<void> showCommentModal(BuildContext context, Event event) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _CommentDialog(event: event);
    },
  );
}

class _CommentDialog extends StatefulWidget {
  final Event event;

  const _CommentDialog({required this.event});

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the dialog visually stable when the keyboard appears.
    // This intentionally ignores the bottom viewInsets so the dialog does not jump.
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        insetPadding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Comment on ${widget.event.eventName}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            height: 140,
            child: TextField(
              controller: _controller,
              autofocus: true,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write your comment here...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF333333), fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
            ),
            onPressed: () async {
              final trimmed = _controller.text.trim();

              if (trimmed.isEmpty) {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Comment not created'),
                    content: Text('Insert a comment'),
                  ),
                );
                return;
              }

              final ok = await addComment(widget.event.id, trimmed);
              if (!mounted) return;

              if (ok) {
                Navigator.of(context).pop();
              } else {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Error'),
                    content: Text('Could not post comment.'),
                  ),
                );
              }
            },
            child: const Text(
              'Post',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
