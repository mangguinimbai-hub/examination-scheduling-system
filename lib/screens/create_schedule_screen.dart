import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConflictResult {
  final String? message;
  final List<String> suggestions;

  ConflictResult({
    this.message,
    this.suggestions = const [],
  });

  bool get hasConflict => message != null;
}

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final courseController = TextEditingController();
  final subjectController = TextEditingController();
  final examDateController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final roomController = TextEditingController();
  final facultyController = TextEditingController();

  bool isLoading = false;

  // Change this based on your actual rooms.
  final List<String> roomOptions = [
    'Lab 1',
    'Lab 2',
    'Room 101',
    'Room 102',
    'Room 103',
    'Room 104',
  ];

  String normalizeText(Object? text) {
    return (text ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String createScheduleId({
    required String course,
    required String subject,
    required String examDate,
    required String startTime,
    required String endTime,
    required String room,
    required String faculty,
  }) {
    final rawKey =
        '${normalizeText(course)}_${normalizeText(subject)}_${normalizeText(examDate)}_${normalizeText(startTime)}_${normalizeText(endTime)}_${normalizeText(room)}_${normalizeText(faculty)}';

    return rawKey
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  int? timeToMinutes(String time) {
    final value = time.trim();

    if (!value.contains(':')) return null;

    final parts = value.split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return hour * 60 + minute;
  }

  String formatMinutesToTime(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool isOverlapping(int start1, int end1, int start2, int end2) {
    return start1 < end2 && start2 < end1;
  }

  bool candidateHasConflict({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required int candidateStart,
    required int candidateEnd,
    required String candidateRoom,
    required String candidateFaculty,
    required String candidateCourse,
  }) {
    for (final doc in docs) {
      final data = doc.data();

      final existingRoom = normalizeText(data['room']);
      final existingFaculty = normalizeText(
        data['faculty'] ?? data['instructor'],
      );
      final existingCourse = normalizeText(data['course']);

      final existingStartTime = (data['startTime'] ?? '').toString().trim();
      final existingEndTime = (data['endTime'] ?? '').toString().trim();

      final existingStart = timeToMinutes(existingStartTime);
      final existingEnd = timeToMinutes(existingEndTime);

      if (existingStart == null || existingEnd == null) {
        continue;
      }

      final hasTimeOverlap = isOverlapping(
        candidateStart,
        candidateEnd,
        existingStart,
        existingEnd,
      );

      final sameRoom = existingRoom == normalizeText(candidateRoom);
      final sameFaculty = existingFaculty == normalizeText(candidateFaculty);
      final sameCourse = existingCourse == normalizeText(candidateCourse);

      if (hasTimeOverlap && (sameRoom || sameFaculty || sameCourse)) {
        return true;
      }
    }

    return false;
  }

  List<String> generateSuggestions({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required int newStart,
    required int newEnd,
    required String room,
    required String faculty,
    required String course,
  }) {
    final List<String> suggestions = [];

    final duration = newEnd - newStart;

    // You can change this depending on your school schedule.
    const schoolStart = 7 * 60; // 07:00
    const schoolEnd = 17 * 60; // 17:00

    // Suggest another available time using the same room.
    for (int start = schoolStart;
    start + duration <= schoolEnd && suggestions.length < 3;
    start += 30) {
      final end = start + duration;

      if (start == newStart && end == newEnd) {
        continue;
      }

      final hasConflict = candidateHasConflict(
        docs: docs,
        candidateStart: start,
        candidateEnd: end,
        candidateRoom: room,
        candidateFaculty: faculty,
        candidateCourse: course,
      );

      if (!hasConflict) {
        suggestions.add(
          'Try ${formatMinutesToTime(start)} - ${formatMinutesToTime(end)} in $room.',
        );
      }
    }

    // Suggest another room using the same selected time.
    for (final availableRoom in roomOptions) {
      if (suggestions.length >= 5) break;

      if (normalizeText(availableRoom) == normalizeText(room)) {
        continue;
      }

      final hasConflict = candidateHasConflict(
        docs: docs,
        candidateStart: newStart,
        candidateEnd: newEnd,
        candidateRoom: availableRoom,
        candidateFaculty: faculty,
        candidateCourse: course,
      );

      if (!hasConflict) {
        suggestions.add(
          'Try $availableRoom at ${formatMinutesToTime(newStart)} - ${formatMinutesToTime(newEnd)}.',
        );
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        'Try another date, another room, or a time outside the conflicting schedule.',
      );
    }

    return suggestions;
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );

    if (pickedDate != null) {
      examDateController.text =
      '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> pickTime(TextEditingController controller) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');

      controller.text = '$hour:$minute';
    }
  }

  Future<ConflictResult> checkConflict({
    required String course,
    required String subject,
    required String examDate,
    required String startTime,
    required String endTime,
    required String room,
    required String faculty,
    required String scheduleId,
  }) async {
    final newStart = timeToMinutes(startTime);
    final newEnd = timeToMinutes(endTime);

    if (newStart == null || newEnd == null) {
      return ConflictResult(message: 'Invalid time format.');
    }

    final duplicateDoc = await FirebaseFirestore.instance
        .collection('schedules')
        .doc(scheduleId)
        .get();

    if (duplicateDoc.exists) {
      return ConflictResult(
        message: 'Duplicate detected: This exact schedule already exists.',
        suggestions: [
          'Change the date, time, room, subject, or faculty before saving again.',
        ],
      );
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('examDate', isEqualTo: examDate)
        .get();

    final docs = snapshot.docs;

    for (final doc in docs) {
      final data = doc.data();

      final existingCourse = normalizeText(data['course']);
      final existingSubject = normalizeText(data['subject']);
      final existingRoom = normalizeText(data['room']);
      final existingFaculty = normalizeText(
        data['faculty'] ?? data['instructor'],
      );

      final existingStartTime = (data['startTime'] ?? '').toString().trim();
      final existingEndTime = (data['endTime'] ?? '').toString().trim();

      final existingStart = timeToMinutes(existingStartTime);
      final existingEnd = timeToMinutes(existingEndTime);

      if (existingStart == null || existingEnd == null) {
        continue;
      }

      final hasTimeOverlap = isOverlapping(
        newStart,
        newEnd,
        existingStart,
        existingEnd,
      );

      final sameCourse = existingCourse == normalizeText(course);
      final sameSubject = existingSubject == normalizeText(subject);
      final sameRoom = existingRoom == normalizeText(room);
      final sameFaculty = existingFaculty == normalizeText(faculty);

      final suggestions = generateSuggestions(
        docs: docs,
        newStart: newStart,
        newEnd: newEnd,
        room: room,
        faculty: faculty,
        course: course,
      );

      if (sameCourse &&
          sameSubject &&
          sameRoom &&
          sameFaculty &&
          existingStartTime == startTime &&
          existingEndTime == endTime) {
        return ConflictResult(
          message: 'Duplicate detected: This exact schedule already exists.',
          suggestions: suggestions,
        );
      }

      if (sameRoom && hasTimeOverlap) {
        return ConflictResult(
          message:
          'Conflict detected: This room is already used during the selected time.',
          suggestions: suggestions,
        );
      }

      if (sameFaculty && hasTimeOverlap) {
        return ConflictResult(
          message:
          'Conflict detected: This faculty already has an exam during the selected time.',
          suggestions: suggestions,
        );
      }

      if (sameCourse && hasTimeOverlap) {
        return ConflictResult(
          message:
          'Conflict detected: This course/section already has an exam during the selected time.',
          suggestions: suggestions,
        );
      }
    }

    return ConflictResult();
  }

  Future<void> saveSchedule() async {
    final course = courseController.text.trim();
    final subject = subjectController.text.trim();
    final examDate = examDateController.text.trim();
    final startTime = startTimeController.text.trim();
    final endTime = endTimeController.text.trim();
    final room = roomController.text.trim();
    final faculty = facultyController.text.trim();

    if (course.isEmpty ||
        subject.isEmpty ||
        examDate.isEmpty ||
        startTime.isEmpty ||
        endTime.isEmpty ||
        room.isEmpty ||
        faculty.isEmpty) {
      showMessage('Please complete all fields.');
      return;
    }

    final startMinutes = timeToMinutes(startTime);
    final endMinutes = timeToMinutes(endTime);

    if (startMinutes == null || endMinutes == null) {
      showMessage('Invalid time format.');
      return;
    }

    if (startMinutes >= endMinutes) {
      showMessage('End time must be later than start time.');
      return;
    }

    final scheduleId = createScheduleId(
      course: course,
      subject: subject,
      examDate: examDate,
      startTime: startTime,
      endTime: endTime,
      room: room,
      faculty: faculty,
    );

    setState(() {
      isLoading = true;
    });

    try {
      final conflictResult = await checkConflict(
        course: course,
        subject: subject,
        examDate: examDate,
        startTime: startTime,
        endTime: endTime,
        room: room,
        faculty: faculty,
        scheduleId: scheduleId,
      );

      if (conflictResult.hasConflict) {
        showConflictDialog(
          conflictResult.message!,
          conflictResult.suggestions,
        );
        return;
      }

      final scheduleRef =
      FirebaseFirestore.instance.collection('schedules').doc(scheduleId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existingSchedule = await transaction.get(scheduleRef);

        if (existingSchedule.exists) {
          throw Exception(
            'Duplicate detected: This exact schedule already exists.',
          );
        }

        transaction.set(scheduleRef, {
          'course': course,
          'courseLower': normalizeText(course),
          'subject': subject,
          'subjectLower': normalizeText(subject),
          'examDate': examDate,
          'startTime': startTime,
          'endTime': endTime,
          'startMinutes': startMinutes,
          'endMinutes': endMinutes,
          'examTime': '$startTime - $endTime',
          'room': room,
          'roomLower': normalizeText(room),
          'faculty': faculty,
          'facultyLower': normalizeText(faculty),
          'instructor': faculty,
          'scheduleKey': scheduleId,
          'createdBy': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      showMessage('Exam schedule saved successfully.');

      courseController.clear();
      subjectController.clear();
      examDateController.clear();
      startTimeController.clear();
      endTimeController.clear();
      roomController.clear();
      facultyController.clear();
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showConflictDialog(String message, List<String> suggestions) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schedule Conflict'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  const Text(
                    'Suggestions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...suggestions.map(
                        (suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('• $suggestion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  @override
  void dispose() {
    courseController.dispose();
    subjectController.dispose();
    examDateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    roomController.dispose();
    facultyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exam Schedule'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          buildTextField(
            controller: courseController,
            label: 'Course / Section',
            icon: Icons.groups,
          ),
          buildTextField(
            controller: subjectController,
            label: 'Subject',
            icon: Icons.book,
          ),
          buildTextField(
            controller: examDateController,
            label: 'Exam Date',
            icon: Icons.calendar_month,
            readOnly: true,
            onTap: pickDate,
          ),
          buildTextField(
            controller: startTimeController,
            label: 'Start Time',
            icon: Icons.access_time,
            readOnly: true,
            onTap: () => pickTime(startTimeController),
          ),
          buildTextField(
            controller: endTimeController,
            label: 'End Time',
            icon: Icons.access_time,
            readOnly: true,
            onTap: () => pickTime(endTimeController),
          ),
          buildTextField(
            controller: roomController,
            label: 'Room',
            icon: Icons.meeting_room,
          ),
          buildTextField(
            controller: facultyController,
            label: 'Faculty / Instructor',
            icon: Icons.person,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : saveSchedule,
              icon: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(isLoading ? 'Saving...' : 'Save Schedule'),
            ),
          ),
        ],
      ),
    );
  }
}