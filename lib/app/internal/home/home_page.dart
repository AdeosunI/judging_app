import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:judging_app/helpers/firestore_collections.dart';
import 'package:judging_app/helpers/types.dart';
import 'package:judging_app/widgets/event_voting_card.dart';

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

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Events tab (placeholder)'),
      ),
    );
  }
}
