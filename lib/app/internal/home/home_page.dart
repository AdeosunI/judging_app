import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:judging_app/helpers/firestore_collections.dart';
import 'package:judging_app/helpers/types.dart';
import 'package:judging_app/widgets/event_voting_card.dart';
import 'package:judging_app/widgets/event_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _index,
            children: const [_VotingTab(), _EventsTab()],
          ),
        ),
        NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.how_to_vote_outlined),
              selectedIcon: Icon(Icons.how_to_vote),
              label: 'Voting',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Events',
            ),
          ],
        ),
      ],
    );
  }
}

class _VotingTab extends StatelessWidget {
  const _VotingTab();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection(eventsCollection)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Something went wrong loading events.'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? const [];

        if (docs.isEmpty) {
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

        final events = docs.map((d) => Event.fromFirestore(d)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,

          itemBuilder: (context, index) {
            return EventVotingCard(event: events[index]);
          },
        );
      },
    );
  }
}

enum _SortCriteria { totalScore, alphabetically, reverseAlphabetically }

class _EventsTab extends StatefulWidget {
  const _EventsTab();

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  _SortCriteria _selectedSort = _SortCriteria.totalScore;
  bool _isLoading = true;

  final Map<String, _EventRow> _rowsById = {};
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
  _userScoreSubs = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;

  String get _userId =>
      _auth.currentUser?.displayName ?? _auth.currentUser!.email!;

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
                _rowsById[event.id] = _EventRow(event: event, userData: null);
              } else {
                _rowsById[event.id] = _EventRow(
                  event: event,
                  userData: existing.userData,
                );
              }

              _ensureUserScoreListener(event);
            }

            final toRemove = _rowsById.keys
                .where((id) => !currentIds.contains(id))
                .toList();
            for (final id in toRemove) {
              _rowsById.remove(id);
              _userScoreSubs.remove(id)?.cancel();
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

  void _ensureUserScoreListener(Event event) {
    if (_userScoreSubs.containsKey(event.id)) return;

    final ref = _db
        .collection(eventsCollection)
        .doc(event.id)
        .collection('userScores')
        .doc(_userId);

    _userScoreSubs[event.id] = ref.snapshots().listen((snap) async {
      UserEventData data;

      if (snap.exists) {
        final map = snap.data();
        if (map == null) return;
        data = UserEventData.fromMap(map);
      } else {
        final initialScores = {for (final c in event.criteria) c: 0};
        await ref.set({'scores': initialScores, 'comments': []});
        data = UserEventData(scores: initialScores);
      }

      if (!mounted) return;
      setState(() {
        final existing = _rowsById[event.id];
        if (existing != null) {
          _rowsById[event.id] = _EventRow(
            event: existing.event,
            userData: data,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    for (final sub in _userScoreSubs.values) {
      sub.cancel();
    }
    _userScoreSubs.clear();
    super.dispose();
  }

  int _totalScore(UserEventData d) => d.scores.values.fold(0, (a, b) => a + b);

  int _compare(_EventRow a, _EventRow b) {
    final aData = a.userData;
    final bData = b.userData;

    if (aData == null && bData == null) return 0;
    if (aData == null) return 1;
    if (bData == null) return -1;

    switch (_selectedSort) {
      case _SortCriteria.totalScore:
        return _totalScore(bData).compareTo(_totalScore(aData));
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

    return Column(
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
              SizedBox(
                width: 190,
                height: 40,
                child: DropdownButtonFormField<_SortCriteria>(
                  value: _selectedSort,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _SortCriteria.totalScore,
                      child: Text('Total Score'),
                    ),
                    DropdownMenuItem(
                      value: _SortCriteria.alphabetically,
                      child: Text('Alphabetically A-Z'),
                    ),
                    DropdownMenuItem(
                      value: _SortCriteria.reverseAlphabetically,
                      child: Text('Alphabetically Z-A'),
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
                    final userData = row.userData;

                    if (userData == null) {
                      return const SizedBox.shrink();
                    }

                    final ranked = _selectedSort == _SortCriteria.totalScore;

                    return KeyedSubtree(
                      key: ValueKey(row.event.id),
                      child: EventCard(
                        event: row.event,
                        userEventData: userData,
                        rank: ranked ? index + 1 : null,
                        isRanked: ranked,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EventRow {
  final Event event;
  final UserEventData? userData;

  const _EventRow({required this.event, required this.userData});
}
