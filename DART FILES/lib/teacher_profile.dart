import 'package:flutter/material.dart';

/*
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Interface',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Student Login'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentDashboard()),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.school),
                label: const Text('Teacher Login'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TeacherDashboard()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  final String userType;
  const Sidebar({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userType == 'Student' ? 'AKASH B C' : 'Dr. Smith'),
            accountEmail: Text(userType == 'Student' ? 'Roll No: 1CR22AD006' : 'Dept: CSE'),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
          ),
          ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard')),
          ListTile(leading: const Icon(Icons.person), title: const Text('Profile')),
          ListTile(leading: const Icon(Icons.book), title: const Text('Syllabus')),
          ListTile(leading: const Icon(Icons.calendar_today), title: const Text('Calendar')),
          ListTile(leading: const Icon(Icons.table_chart), title: const Text('Time Table')),
          ListTile(leading: const Icon(Icons.library_books), title: const Text('Library')),
          ListTile(leading: const Icon(Icons.payment), title: const Text('Fees Details')),
          ListTile(leading: const Icon(Icons.event_busy), title: const Text('Leave Details')),
          ListTile(leading: const Icon(Icons.house), title: const Text('Hostel')),
          ListTile(leading: const Icon(Icons.contact_mail), title: const Text('Contact Mentor')),
          ListTile(leading: const Icon(Icons.article), title: const Text('Blogs')),
        ],
      ),
    );
  }
}

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(userType: 'Student'),
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              InfoCard(title: 'Announcements', value: '0', color: Colors.red),
              InfoCard(title: 'Attendance', value: '78.28%', color: Colors.orange),
              InfoCard(title: 'Assessment', value: '0', color: Colors.indigo),
              InfoCard(title: 'Task', value: '14', color: Colors.blue),
              InfoCard(title: 'Placement', value: '0', color: Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Today s Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: const [
                ListTile(title: Text('08:00 AM - 10:00 AM'), subtitle: Text('ML Lab')),
                ListTile(title: Text('10:20 AM - 11:20 AM'), subtitle: Text('ML')),
                ListTile(title: Text('11:20 AM - 12:20 PM'), subtitle: Text('NLP')),
                ListTile(title: Text('01:00 PM - 02:00 PM'), subtitle: Text('REPP')),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const InfoCard({super.key, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 100,
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

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
              CircleAvatar(
                backgroundImage: NetworkImage(teacherPhotoUrl),
              ),
              const SizedBox(width: 10),
              Text(
                teacherName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
        body: const TabBarView(
          children: [
            ClassInfoTab(),
            MarkAttendanceTab(),
          ],
        ),
      ),
    );
  }
}


class ClassInfoTab extends StatelessWidget {
  const ClassInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Class Name')),
          DataColumn(label: Text('Timing')),
          DataColumn(label: Text('Building')),
        ],
        rows: const [
          DataRow(cells: [
            DataCell(Text('AI & DS A')),
            DataCell(Text('10:00 - 11:00')),
            DataCell(Text('Block A')),
          ]),
          DataRow(cells: [
            DataCell(Text('CSE B')),
            DataCell(Text('11:00 - 12:00')),
            DataCell(Text('Block B')),
          ]),
          DataRow(cells: [
            DataCell(Text('ECE C')),
            DataCell(Text('01:00 - 02:00')),
            DataCell(Text('Block C')),
          ]),
        ],
      ),
    );
  }
}

class MarkAttendanceTab extends StatelessWidget {
  const MarkAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance Marked Successfully!')),
          );
        },
        child: const Text('Mark Attendance'),
      ),
    );
  }
}
*/
