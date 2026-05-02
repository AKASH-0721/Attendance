import 'package:flutter/material.dart';
import '../models/teacher_model.dart';
import '../services/auth_service.dart';
import '../services/teacher_service.dart';
import '../services/student_service.dart';
import 'class_info_tab.dart';
import 'mark_attendance_tab.dart';
import 'edit_teacher_profile.dart';
import 'teacher_schedule.dart';
import 'teacher_reports.dart';
import 'teacher_settings.dart';

class TeacherDashboard extends StatefulWidget {
  final String teacherName;
  final String teacherPhotoUrl;

  const TeacherDashboard({
    super.key,
    required this.teacherName,
    required this.teacherPhotoUrl,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TeacherService _teacherService = TeacherService();
  final StudentService _studentService = StudentService();
  
  late TabController _tabController;
  Teacher? _currentTeacher;
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final teacher = await _authService.getTeacherData(user.uid);
        if (teacher != null) {
          final stats = await _getTeacherStats(teacher);
          setState(() {
            _currentTeacher = teacher;
            _dashboardStats = stats;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load teacher data: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _getTeacherStats(Teacher teacher) async {
    try {
      // Get total students across all classes
      int totalStudents = 0;
      Map<String, int> classStudentCounts = {};
      
      for (String className in teacher.classes) {
        // Extract section from class name (e.g., "AI & DS A" -> "A")
        String section = className.split(' ').last;
        final students = await _studentService.getStudentsBySection(section);
        classStudentCounts[className] = students.length;
        totalStudents += students.length;
      }

      return {
        'totalClasses': teacher.classes.length,
        'totalStudents': totalStudents,
        'classStudentCounts': classStudentCounts,
        'attendanceToday': 0, // TODO: Implement attendance tracking
        'averageAttendance': 85.5, // TODO: Calculate from actual data
      };
    } catch (e) {
      return {
        'totalClasses': teacher.classes.length,
        'totalStudents': 0,
        'classStudentCounts': {},
        'attendanceToday': 0,
        'averageAttendance': 0.0,
      };
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to sign out: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.teacherPhotoUrl.isNotEmpty
                  ? NetworkImage(widget.teacherPhotoUrl)
                  : null,
              backgroundColor: Colors.indigo,
              child: widget.teacherPhotoUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teacherName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_currentTeacher != null)
                    Text(
                      _currentTeacher!.designation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeacherData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  if (_currentTeacher != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTeacherProfilePage(teacher: _currentTeacher!),
                      ),
                    ).then((_) => _loadTeacherData());
                  }
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherSettingsPage(teacher: _currentTeacher),
                    ),
                  );
                  break;
                case 'logout':
                  _signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.class_), text: 'Classes'),
            Tab(icon: Icon(Icons.check_circle), text: 'Attendance'),
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
            Tab(icon: Icon(Icons.analytics), text: 'Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                ClassInfoTab(),
                MarkAttendanceTab(),
                TeacherSchedulePage(teacher: _currentTeacher),
                TeacherReportsPage(teacher: _currentTeacher),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to manage your classes today?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    DateTime.now().toString().split(' ')[0],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Cards
          const Text(
            'Quick Stats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Total Classes',
                _dashboardStats['totalClasses']?.toString() ?? '0',
                Icons.class_,
                Colors.blue,
              ),
              _buildStatCard(
                'Total Students',
                _dashboardStats['totalStudents']?.toString() ?? '0',
                Icons.people,
                Colors.green,
              ),
              _buildStatCard(
                'Today\'s Attendance',
                '${_dashboardStats['attendanceToday'] ?? 0}',
                Icons.check_circle,
                Colors.orange,
              ),
              _buildStatCard(
                'Avg. Attendance',
                '${_dashboardStats['averageAttendance']?.toStringAsFixed(1) ?? '0.0'}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildActionCard(
                'Mark Attendance',
                Icons.camera_alt,
                Colors.indigo,
                () => _tabController.animateTo(2),
              ),
              _buildActionCard(
                'View Classes',
                Icons.class_,
                Colors.blue,
                () => _tabController.animateTo(1),
              ),
              _buildActionCard(
                'Check Schedule',
                Icons.schedule,
                Colors.green,
                () => _tabController.animateTo(3),
              ),
              _buildActionCard(
                'View Reports',
                Icons.analytics,
                Colors.orange,
                () => _tabController.animateTo(4),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Class Overview
          if (_currentTeacher != null && _currentTeacher!.classes.isNotEmpty) ...[
            const Text(
              'Your Classes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentTeacher!.classes.length,
                itemBuilder: (context, index) {
                  final className = _currentTeacher!.classes[index];
                  final studentCount = _dashboardStats['classStudentCounts']?[className] ?? 0;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      child: Text(
                        className.split(' ').last,
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      className,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('$studentCount students'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to specific class details
                      _tabController.animateTo(1);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
