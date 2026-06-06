import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewSchedulesScreen extends StatelessWidget {
  const ViewSchedulesScreen({super.key});

  int timeToMinutes(String time) {
    final value = time.trim();

    if (!value.contains(':')) return 0;

    final parts = value.split(':');

    if (parts.length != 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Schedules'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final schedules = snapshot.data?.docs ?? [];

          if (schedules.isEmpty) {
            return const Center(
              child: Text('No exam schedules found.'),
            );
          }

          schedules.sort((a, b) {
            final dataA = a.data();
            final dataB = b.data();

            final dateA = (dataA['examDate'] ?? '').toString();
            final dateB = (dataB['examDate'] ?? '').toString();

            final dateCompare = dateA.compareTo(dateB);

            if (dateCompare != 0) {
              return dateCompare;
            }

            final startA = timeToMinutes((dataA['startTime'] ?? '').toString());
            final startB = timeToMinutes((dataB['startTime'] ?? '').toString());

            return startA.compareTo(startB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final data = schedules[index].data();

              final course = (data['course'] ?? 'No course').toString();
              final subject = (data['subject'] ?? 'No subject').toString();
              final examDate = (data['examDate'] ?? 'No date').toString();

              final examTime = (data['examTime'] ??
                  '${data['startTime'] ?? ''} - ${data['endTime'] ?? ''}')
                  .toString();

              final room = (data['room'] ?? 'No room').toString();

              final faculty =
              (data['faculty'] ?? data['instructor'] ?? 'No faculty')
                  .toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_month,
                    color: Colors.blue,
                  ),
                  title: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Course: $course\n'
                          'Date: $examDate\n'
                          'Time: $examTime\n'
                          'Room: $room\n'
                          'Faculty: $faculty',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}