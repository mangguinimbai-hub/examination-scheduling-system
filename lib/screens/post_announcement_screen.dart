import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostAnnouncementScreen extends StatefulWidget {
  const PostAnnouncementScreen({super.key});

  @override
  State<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  bool isLoading = false;

  String selectedCategory = 'General';
  String selectedAudience = 'All';

  final List<String> categories = [
    'General',
    'Exam',
    'Schedule',
    'Important',
    'Reminder',
  ];

  final List<String> audiences = [
    'All',
    'Students',
    'Faculty',
    'Admin',
  ];

  Future<void> postAnnouncement() async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      showMessage('Please complete all fields.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'message': message,
        'category': selectedCategory,
        'audience': selectedAudience,
        'postedBy': currentUser?.uid,
        'postedByEmail': currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      showMessage('Announcement posted successfully.');

      titleController.clear();
      messageController.clear();

      setState(() {
        selectedCategory = 'General';
        selectedAudience = 'All';
      });
    } catch (e) {
      showMessage('Failed to post announcement: $e');
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
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: maxLines == 1 ? Icon(icon) : null,
          alignLabelWithHint: maxLines > 1,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: isLoading ? null : onChanged,
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Announcement'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Create Announcement',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Post important announcements for students, faculty, or all users.',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),

          buildTextField(
            controller: titleController,
            label: 'Announcement Title',
            icon: Icons.title,
          ),

          buildTextField(
            controller: messageController,
            label: 'Announcement Message',
            icon: Icons.message,
            maxLines: 5,
          ),

          buildDropdown(
            label: 'Category',
            value: selectedCategory,
            items: categories,
            icon: Icons.category,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedCategory = value;
                });
              }
            },
          ),

          buildDropdown(
            label: 'Audience',
            value: selectedAudience,
            items: audiences,
            icon: Icons.people,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedAudience = value;
                });
              }
            },
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : postAnnouncement,
              icon: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send),
              label: Text(
                isLoading ? 'Posting...' : 'Post Announcement',
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Divider(),

          const SizedBox(height: 10),

          const Text(
            'Recent Announcements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Failed to load announcements.');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No announcements posted yet.');
              }

              final announcements = snapshot.data!.docs;

              return Column(
                children: announcements.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final title = data['title'] ?? 'No Title';
                  final message = data['message'] ?? 'No Message';
                  final category = data['category'] ?? 'General';
                  final audience = data['audience'] ?? 'All';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.campaign),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$message\n\nCategory: $category | Audience: $audience',
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}