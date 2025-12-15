import 'package:flutter/material.dart';
import 'package:judging_app/app/app_widget.dart';
import 'package:judging_app/helpers/types.dart';
import 'package:routefly/routefly.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final UserEventData userEventData;
  final int? rank;
  final bool isRanked;
  final bool isAverageScore;

  const EventCard({
    super.key,
    required this.event,
    required this.userEventData,
    this.rank,
    this.isRanked = false,
    this.isAverageScore = false,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool isExpanded = false;

  Color get backgroundColor {
    if (!widget.isRanked) return Colors.white;

    if (widget.rank == 1) return const Color(0xFFFFD700);
    if (widget.rank == 2) return const Color(0xFFD3D3D3);
    if (widget.rank == 3) return const Color(0xFFCE8946);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.userEventData.scores.entries.toList();
    final totalScore = widget.userEventData.scores.values.fold(
      0,
      (a, b) => a + b,
    );
    final maxScore = widget.userEventData.scores.length * 10;
    final averageScore = widget.userEventData.scores.isEmpty
        ? 0
        : totalScore / widget.userEventData.scores.length;

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.isRanked)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      '#${widget.rank}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.event.eventName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: isExpanded ? 1 : 0,
                  child: _expandedContent(scores),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Routefly.push(
                      routePaths.comments.$id.comments.replaceFirst(
                        '[id]',
                        widget.event.id,
                      ),
                    );
                  },
                  child: const Text(
                    'View comments',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  widget.isAverageScore
                      ? 'Average user score: ${averageScore.toStringAsFixed(1)}'
                      : 'Total score: $totalScore / $maxScore',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedContent(List<MapEntry<String, int>> scores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(widget.event.eventDesc, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 12),
        Text(
          'Event Date: ${_formatDate(widget.event.eventDate.toDate())}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Column(
          children: scores
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ': ${entry.value}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
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
