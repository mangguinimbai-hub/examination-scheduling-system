import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  bool isOverlapping(int start1, int end1, int start2, int end2) {
    return start1 < end2 && start2 < end1;
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

  Future<String?> checkConflict({
    required String examDate,
    required String startTime,
    required String endTime,
    required String room,
    required String faculty,
  }) async {
    final newStart = timeToMinutes(startTime);
    final newEnd = timeToMinutes(endTime);

    if (newStart == null || newEnd == null) {
      return 'Invalid time format.';
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('examDate', isEqualTo: examDate)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final existingRoom =
      (data['room'] ?? '').toString().trim().toLowerCase();

      final existingFaculty =
      (data['faculty'] ?? data['instructor'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

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

      final sameRoom = existingRoom == room.trim().toLowerCase();
      final sameFaculty = existingFaculty == faculty.trim().toLowerCase();

      if (sameRoom && hasTimeOverlap) {
        return 'Conflict detected: This room is already used during the selected time.';
      }

      if (sameFaculty && hasTimeOverlap) {
        return 'Conflict detected: This faculty already has an exam during the selected time.';
      }
    }

    return null;
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

    setState(() {
      isLoading = true;
    });

    try {
      final conflictMessage = await checkConflict(
        examDate: examDate,
        startTime: startTime,
        endTime: endTime,
        room: room,
        faculty: faculty,
      );

      if (conflictMessage != null) {
        showMessage(conflictMessage);
        return;
      }

      await FirebaseFirestore.instance.collection('schedules').add({
        'course': course,
        'subject': subject,
        'examDate': examDate,
        'startTime': startTime,
        'endTime': endTime,
        'examTime': '$startTime - $endTime',
        'room': room,
        'faculty': faculty,
        'instructor': faculty,
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
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
      showMessage('Failed to save schedule: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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