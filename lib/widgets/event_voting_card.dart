import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:judging_app/helpers/firestore_collections.dart';
import 'package:judging_app/helpers/types.dart';
import 'comment_modal.dart';

class EventVotingCard extends StatefulWidget {
  final Event event;

  const EventVotingCard({super.key, required this.event});

  @override
  State<EventVotingCard> createState() => _EventVotingCardState();
}

class _EventVotingCardState extends State<EventVotingCard> {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _scoresSub;

  Map<String, int>? userScores;

  late final String userId;

  @override
  void initState() {
    super.initState();
    userId = auth.currentUser?.displayName ?? auth.currentUser!.email!;
    _listenToScores();
  }

  void _listenToScores() {
    _scoresSub?.cancel();
    _scoresSub = null;

    final docRef = db
        .collection(eventsCollection)
        .doc(widget.event.id)
        .collection('userScores')
        .doc(userId);

    _scoresSub = docRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        final initialScores = {for (final c in widget.event.criteria) c: 0};

        await docRef.set({'scores': initialScores, 'comments': []});

        if (!mounted) return;
        setState(() {
          userScores = initialScores;
        });
      } else {
        final data = snapshot.data();
        if (data == null) return;

        final scores = Map<String, int>.from(
          (data['scores'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as int),
          ),
        );

        if (!mounted) return;
        setState(() {
          userScores = scores;
        });
      }
    });
  }

  Future<void> _updateScore(String criterion, int value) async {
    final docRef = db
        .collection(eventsCollection)
        .doc(widget.event.id)
        .collection('userScores')
        .doc(userId);

    await docRef.update({'scores.$criterion': value});
  }

  @override
  void dispose() {
    _scoresSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userScores == null) {
      return const SizedBox.shrink();
    }

    final sortedScores = userScores!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.eventName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.eventDesc,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${_formatDate(widget.event.eventDate.toDate())}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedScores.length,
                  itemBuilder: (context, index) {
                    final entry = sortedScores[index];
                    return _criterionSlider(entry.key, entry.value);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: TextButton(
                onPressed: () {
                  showCommentModal(context, widget.event);
                },
                child: const Text(
                  'Add Comment',
                  style: TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criterionSlider(String criterion, int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_capitalize(criterion)}: $score',
          style: const TextStyle(fontSize: 16),
        ),
        Slider(
          value: score.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          onChanged: (value) {
            setState(() {
              userScores![criterion] = value.toInt();
            });
          },
          onChangeEnd: (value) {
            _updateScore(criterion, value.toInt());
          },
          activeColor: const Color(0xFF1EB1FC),
          inactiveColor: Colors.grey,
          thumbColor: const Color(0xFF007AFF),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}
