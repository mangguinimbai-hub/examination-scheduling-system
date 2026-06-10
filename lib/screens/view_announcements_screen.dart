import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAnnouncementsScreen extends StatelessWidget {
  const ViewAnnouncementsScreen({super.key});

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      final year = date.year;
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$year-$month-$day  $hour:$minute';
    }

    return 'No date';
  }

  Future<void> deleteAnnouncement(
      BuildContext context,
      String announcementId,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: const Text(
            'Are you sure you want to delete this announcement?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(announcementId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement deleted successfully.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete announcement: $e'),
        ),
      );
    }
  }

  void showAnnouncementDetails(
      BuildContext context,
      Map<String, dynamic> data,
      ) {
    final title = data['title'] ?? 'No Title';
    final message = data['message'] ?? 'No Message';
    final category = data['category'] ?? 'General';
    final audience = data['audience'] ?? 'All';
    final postedByEmail = data['postedByEmail'] ?? 'Unknown';
    final createdAt = formatDate(data['createdAt']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                const Divider(),
                Text('Category: $category'),
                Text('Audience: $audience'),
                Text('Posted by: $postedByEmail'),
                Text('Date posted: $createdAt'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'exam':
        return Colors.blue;
      case 'schedule':
        return Colors.green;
      case 'important':
        return Colors.red;
      case 'reminder':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'exam':
        return Icons.quiz;
      case 'schedule':
        return Icons.calendar_month;
      case 'important':
        return Icons.priority_high;
      case 'reminder':
        return Icons.notifications;
      default:
        return Icons.campaign;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Announcements'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load announcements.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No announcements posted yet.'),
            );
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final doc = announcements[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'No Title';
              final message = data['message'] ?? 'No Message';
              final category = data['category'] ?? 'General';
              final audience = data['audience'] ?? 'All';
              final createdAt = formatDate(data['createdAt']);

              final categoryColor = getCategoryColor(category);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    showAnnouncementDetails(context, data);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: categoryColor.withOpacity(0.15),
                              child: Icon(
                                getCategoryIcon(category),
                                color: categoryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  deleteAnnouncement(context, doc.id);
                                }
                              },
                              itemBuilder: (context) {
                                return const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Chip(
                              label: Text(category),
                              avatar: Icon(
                                getCategoryIcon(category),
                                size: 18,
                              ),
                            ),
                            Chip(
                              label: Text('Audience: $audience'),
                              avatar: const Icon(
                                Icons.people,
                                size: 18,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              createdAt,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
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