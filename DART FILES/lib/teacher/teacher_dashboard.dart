import 'package:flutter/material.dart';
import '../sidebar.dart';
import 'class_info_tab.dart';
import 'mark_attendance_tab.dart';

class TeacherDashboard extends StatelessWidget {
  final String teacherName;
  final String teacherPhotoUrl;

  const TeacherDashboard({
    super.key,
    required this.teacherName,
    required this.teacherPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const Sidebar(userType: 'Teacher'),
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(teacherPhotoUrl)),
              const SizedBox(width: 10),
              Text(
                teacherName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Class Info'),
              Tab(text: 'Mark Attendance'),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const TabBarView(children: [ClassInfoTab(), MarkAttendanceTab()]),
      ),
    );
  }
}
