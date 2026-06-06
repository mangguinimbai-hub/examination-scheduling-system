import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/dashboard_button.dart';
import '../widgets/dashboard_layout.dart';
import 'create_schedule_screen.dart';
import 'view_schedules_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added next.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Admin Dashboard',
      roleText: 'Welcome, Admin',
      children: [
        DashboardButton(
          icon: Icons.add_circle,
          label: 'Create Exam Schedule',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateScheduleScreen(),
              ),
            );
          },
        ),

        DashboardButton(
          icon: Icons.list,
          label: 'View Exam Schedules',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ViewSchedulesScreen(),
              ),
            );
          },
        ),

        DashboardButton(
          icon: Icons.campaign,
          label: 'Post Announcement',
          onTap: () {
            showComingSoon(context, 'Post Announcement');
          },
        ),

        DashboardButton(
          icon: Icons.announcement,
          label: 'View Announcements',
          onTap: () {
            showComingSoon(context, 'View Announcements');
          },
        ),

        DashboardButton(
          icon: Icons.logout,
          label: 'Logout',
          onTap: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    );
  }
}