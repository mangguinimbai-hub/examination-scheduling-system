import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/dashboard_button.dart';
import '../widgets/dashboard_layout.dart';
import 'view_schedules_screen.dart';
import 'view_announcements_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Student Dashboard',
      roleText: 'Welcome, Student',
      children: [
        DashboardButton(
          icon: Icons.schedule,
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
          icon: Icons.announcement,
          label: 'View Announcements',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ViewAnnouncementsScreen(),
              ),
            );
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