import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String comment;
  final Timestamp date;

  Comment({required this.comment, required this.date});

  factory Comment.fromMap(Map<String, dynamic> data) {
    return Comment(
      comment: data['comment'] as String,
      date: data['date'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {'comment': comment, 'date': date};
  }
}

class UserEventData {
  final Map<String, int> scores;

  UserEventData({required this.scores});

  factory UserEventData.fromMap(Map<String, dynamic> data) {
    return UserEventData(
      scores: Map<String, int>.from(
        (data['scores'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as int),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {'scores': scores};
  }
}

class Event {
  final String id;
  final String eventName;
  final String eventDesc;
  final Timestamp eventDate;
  final List<String> criteria;

  final Map<String, List<Comment>> comments;

  Event({
    required this.id,
    required this.eventName,
    required this.eventDesc,
    required this.eventDate,
    required this.criteria,
    required this.comments,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawComments = data['comments'] as Map<String, dynamic>? ?? {};

    return Event(
      id: doc.id,
      eventName: data['eventName'] as String,
      eventDesc: data['eventDesc'] as String,
      eventDate: data['eventDate'] as Timestamp,
      criteria: List<String>.from(data['criteria'] as List<dynamic>),
      comments: rawComments.map(
        (user, value) => MapEntry(
          user,
          (value as List<dynamic>)
              .map((c) => Comment.fromMap(c as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'eventDesc': eventDesc,
      'eventDate': eventDate,
      'criteria': criteria,
      'comments': comments.map(
        (user, commentList) =>
            MapEntry(user, commentList.map((c) => c.toMap()).toList()),
      ),
    };
  }
}
