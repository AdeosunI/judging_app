import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:judging_app/helpers/firestore_collections.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  final _db = FirebaseFirestore.instance;

  final _eventNameController = TextEditingController();
  final _eventDescController = TextEditingController();

  DateTime _eventDate = DateTime.now();
  final List<TextEditingController> _criteriaControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  bool _submitting = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescController.dispose();
    for (final c in _criteriaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _eventDate = picked;
    });
  }

  void _addCriterion() {
    if (_criteriaControllers.length >= 5) {
      _showDialog(
        'Validation Error',
        'You can have a maximum of five criteria.',
      );
      return;
    }
    setState(() {
      _criteriaControllers.add(TextEditingController());
    });
  }

  void _deleteCriterion(int index) {
    if (_criteriaControllers.length <= 3) {
      _showDialog('Validation Error', 'You must have at least three criteria.');
      return;
    }

    final c = _criteriaControllers.removeAt(index);
    c.dispose();
    setState(() {});
  }

  String _normalizeCriterion(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Future<void> _showDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _addEvent({
    required String eventName,
    required String eventDesc,
    required DateTime eventDate,
    required List<String> criteria,
  }) async {
    try {
      await _db.collection(eventsCollection).add({
        'eventName': eventName,
        'eventDesc': eventDesc,
        'eventDate': Timestamp.fromDate(eventDate),
        'criteria': criteria,
        'comments': <String, dynamic>{},
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
      return true;
    } catch (e) {
      await _showDialog('Error', 'Error creating event: $e');
      return false;
    }
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;

    final name = _eventNameController.text.trim();
    if (name.isEmpty) {
      await _showDialog('Validation Error', 'You have to put in an event name');
      return;
    }

    final desc = _eventDescController.text.trim();
    if (desc.isEmpty) {
      await _showDialog(
        'Validation Error',
        'You have to put in an event description',
      );
      return;
    }

    final processedCriteria = _criteriaControllers
        .map((c) => _normalizeCriterion(c.text))
        .where((c) => c.isNotEmpty)
        .toList();

    if (processedCriteria.length < 3) {
      await _showDialog(
        'Validation Error',
        'Please enter at least three criteria.',
      );
      return;
    }

    final hasDuplicates =
        processedCriteria.toSet().length != processedCriteria.length;
    if (hasDuplicates) {
      await _showDialog('Validation Error', 'Criteria must be unique.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    final added = await _addEvent(
      eventName: name,
      eventDesc: desc,
      eventDate: _eventDate,
      criteria: processedCriteria,
    );

    if (!mounted) return;

    setState(() {
      _submitting = false;
    });

    if (!added) return;

    _eventNameController.clear();
    _eventDescController.clear();

    for (final c in _criteriaControllers) {
      c.clear();
    }

    if (!mounted) return;
    setState(() {
      _eventDate = DateTime.now();
      while (_criteriaControllers.length > 3) {
        final last = _criteriaControllers.removeLast();
        last.dispose();
      }
    });

    await _showDialog('Success', 'Event successfully created');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Name',
              style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _eventNameController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter Event Name',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Event Description',
              style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _eventDescController,
              minLines: 2,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Enter Event Description',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Voting Criteria',
              style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(_criteriaControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _criteriaControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Criterion ${index + 1}',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _deleteCriterion(index),
                        child: const Text(
                          '✕',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            if (_criteriaControllers.length < 5)
              Center(
                child: TextButton(
                  onPressed: _addCriterion,
                  child: const Text(
                    '+',
                    style: TextStyle(fontSize: 24, color: Color(0xFF007BFF)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Event Date',
              style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _pickDate,
                child: Text(
                  MaterialLocalizations.of(context).formatFullDate(_eventDate),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _submitting ? null : _handleSubmit,
                child: Text(
                  _submitting ? 'Adding…' : 'Add Event',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
}
