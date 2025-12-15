import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:judging_app/helpers/firestore_collections.dart';
import 'package:judging_app/helpers/types.dart';
import 'package:judging_app/widgets/event_card.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

enum _SortCriteria { averageScore, alphabetically, reverseAlphabetically }

class _AppPageState extends State<AppPage> {
  final _db = FirebaseFirestore.instance;

  _SortCriteria _selectedSort = _SortCriteria.averageScore;
  bool _isLoading = true;

  final Map<String, _EventRow> _rowsById = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _userScoresSubs = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;

  @override
  void initState() {
    super.initState();

    _eventsSub = _db
        .collection(eventsCollection)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
            });

            final currentIds = <String>{};

            for (final doc in snap.docs) {
              final event = Event.fromFirestore(doc);
              currentIds.add(event.id);

              final existing = _rowsById[event.id];
              if (existing == null) {
                _rowsById[event.id] = _EventRow(
                  event: event,
                  userEventData: null,
                );
              } else {
                _rowsById[event.id] = _EventRow(
                  event: event,
                  userEventData: existing.userEventData,
                );
              }

              _ensureUserScoresListener(event);
            }

            final toRemove = _rowsById.keys
                .where((id) => !currentIds.contains(id))
                .toList();
            for (final id in toRemove) {
              _rowsById.remove(id);
              _userScoresSubs.remove(id)?.cancel();
            }

            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
        );
  }

  void _ensureUserScoresListener(Event event) {
    if (_userScoresSubs.containsKey(event.id)) return;

    final ref = _db
        .collection(eventsCollection)
        .doc(event.id)
        .collection('userScores')
        .snapshots();

    _userScoresSubs[event.id] = ref.listen((subSnap) {
      final scoresSum = <String, num>{};
      final scoresCount = <String, int>{};

      for (final userDoc in subSnap.docs) {
        final data = userDoc.data();
        final scores = data['scores'];
        if (scores is! Map) continue;

        for (final entry in scores.entries) {
          final criterion = entry.key?.toString();
          final value = entry.value;
          if (criterion == null) continue;

          final score = value is num ? value : num.tryParse(value.toString());
          if (score == null) continue;

          scoresSum[criterion] = (scoresSum[criterion] ?? 0) + score;
          scoresCount[criterion] = (scoresCount[criterion] ?? 0) + 1;
        }
      }

      final avgScores = <String, int>{};
      for (final entry in scoresSum.entries) {
        final c = entry.key;
        final count = scoresCount[c] ?? 0;
        if (count <= 0) continue;
        final avg = entry.value / count;
        avgScores[c] = avg.round();
      }

      final userEventData = UserEventData(scores: avgScores);

      if (!mounted) return;
      setState(() {
        final existing = _rowsById[event.id];
        if (existing != null) {
          _rowsById[event.id] = _EventRow(
            event: existing.event,
            userEventData: userEventData,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    for (final sub in _userScoresSubs.values) {
      sub.cancel();
    }
    _userScoresSubs.clear();
    super.dispose();
  }

  double _overallAverage(UserEventData d) {
    if (d.scores.isEmpty) return 0;
    final sum = d.scores.values.fold<num>(0, (a, b) => a + b);
    return sum / d.scores.length;
  }

  int _compare(_EventRow a, _EventRow b) {
    final aData = a.userEventData;
    final bData = b.userEventData;

    if (aData == null && bData == null) return 0;
    if (aData == null) return 1;
    if (bData == null) return -1;

    switch (_selectedSort) {
      case _SortCriteria.averageScore:
        return _overallAverage(bData).compareTo(_overallAverage(aData));
      case _SortCriteria.alphabetically:
        return a.event.eventName.compareTo(b.event.eventName);
      case _SortCriteria.reverseAlphabetically:
        return b.event.eventName.compareTo(a.event.eventName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rowsById.values.toList()..sort(_compare);

    if (!_isLoading && rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'There are no events to vote on yet. Go to the settings page to add events.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF9F9F9),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<_SortCriteria>(
                          value: _selectedSort,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: _SortCriteria.averageScore,
                              child: Text(
                                'Average user score',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: _SortCriteria.alphabetically,
                              child: Text(
                                'Alphabetically A-Z',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: _SortCriteria.reverseAlphabetically,
                              child: Text(
                                'Alphabetically Z-A',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedSort = v;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && rows.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final data = row.userEventData;

                      if (data == null) {
                        return const SizedBox.shrink();
                      }

                      final ranked =
                          _selectedSort == _SortCriteria.averageScore;

                      return KeyedSubtree(
                        key: ValueKey(row.event.id),
                        child: EventCard(
                          event: row.event,
                          userEventData: data,
                          rank: ranked ? index + 1 : null,
                          isRanked: ranked,
                          isAverageScore: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventRow {
  final Event event;
  final UserEventData? userEventData;

  const _EventRow({required this.event, required this.userEventData});
}
