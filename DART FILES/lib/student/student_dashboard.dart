import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import 'student_attendance.dart';
import 'student_schedule.dart';
import 'student_assignments.dart';
import 'student_profile_edit.dart';
import 'student_settings.dart';

class StudentProfile extends StatefulWidget {
  final Student? student;
  
  const StudentProfile({super.key, this.student});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StudentService _studentService = StudentService();
  final AttendanceService _attendanceService = AttendanceService();
  
  late TabController _tabController;
  Student? _currentStudent;
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final studentData = await _authService.getStudentData(user.uid);
        if (studentData != null) {
          final student = Student.fromMap(user.uid, studentData);
          final stats = await _getStudentStats(student);
          setState(() {
            _currentStudent = student;
            _dashboardStats = stats;
            _isLoading = false;
          });
        }
      } else if (widget.student != null) {
        final stats = await _getStudentStats(widget.student!);
        setState(() {
          _currentStudent = widget.student;
          _dashboardStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load student data: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _getStudentStats(Student student) async {
    try {
      // Fetch real attendance data
      AttendanceSummary attendanceSummary = await _attendanceService.getStudentAttendanceSummary(
        studentRollNumber: student.rollNumber,
      );
      
      // Calculate subject count from attendance summary
      int totalSubjects = attendanceSummary.subjectWise.length;
      
      // Sample data for other stats (these would come from other services in a complete app)
      return {
        'attendancePercentage': attendanceSummary.attendancePercentage,
        'totalClasses': attendanceSummary.totalClasses,
        'attendedClasses': attendanceSummary.attendedClasses,
        'totalSubjects': totalSubjects > 0 ? totalSubjects : 6, // Default to 6 if no subjects found
        'assignmentsDue': 4,
        'tasksCompleted': 12,
        'totalTasks': 15,
        'unreadMessages': 3,
        'upcomingExams': 2,
        'gpa': 8.2,
        'rank': 15,
        'totalStudents': 120,
        'subjectWiseAttendance': attendanceSummary.subjectWise,
      };
    } catch (e) {
      print('Error fetching student stats: ${e.toString()}');
      // Return default values if attendance fetch fails
      return {
        'attendancePercentage': 0.0,
        'totalClasses': 0,
        'attendedClasses': 0,
        'totalSubjects': 6,
        'assignmentsDue': 0,
        'tasksCompleted': 0,
        'totalTasks': 0,
        'unreadMessages': 0,
        'upcomingExams': 0,
        'gpa': 0.0,
        'rank': 0,
        'totalStudents': 0,
        'subjectWiseAttendance': <String, SubjectAttendance>{},
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
              backgroundImage: _currentStudent?.photo.isNotEmpty == true
                  ? NetworkImage(_currentStudent!.photo)
                  : null,
              backgroundColor: Colors.indigo,
              child: _currentStudent?.photo.isEmpty != false
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStudent?.name ?? 'Student Dashboard',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_currentStudent != null)
                    Text(
                      'Roll: ${_currentStudent!.rollNumber}',
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
            onPressed: _loadStudentData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  if (_currentStudent != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentProfileEditPage(student: _currentStudent!),
                      ),
                    ).then((_) => _loadStudentData());
                  }
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentSettingsPage(student: _currentStudent),
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
            Tab(icon: Icon(Icons.check_circle), text: 'Attendance'),
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
            Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.analytics), text: 'Performance'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                StudentAttendancePage(student: _currentStudent),
                StudentSchedulePage(student: _currentStudent),
                StudentAssignmentsPage(student: _currentStudent),
                _buildProfileTab(),
                _buildPerformanceTab(),
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
                  Text(
                    'Welcome back, ${_currentStudent?.name.split(' ').first ?? 'Student'}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready for another productive day?',
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

          // Quick Stats
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
                'Attendance',
                '${_dashboardStats['attendancePercentage']?.toStringAsFixed(1) ?? '0.0'}%',
                Icons.check_circle,
                _getAttendanceColor(_dashboardStats['attendancePercentage'] ?? 0),
              ),
              _buildStatCard(
                'Assignments Due',
                '${_dashboardStats['assignmentsDue'] ?? 0}',
                Icons.assignment,
                Colors.orange,
              ),
              _buildStatCard(
                'GPA',
                '${_dashboardStats['gpa']?.toStringAsFixed(1) ?? '0.0'}',
                Icons.star,
                Colors.green,
              ),
              _buildStatCard(
                'Class Rank',
                '${_dashboardStats['rank'] ?? 0}/${_dashboardStats['totalStudents'] ?? 0}',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Today's Schedule
          const Text(
            'Today\'s Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildScheduleItem('9:00 - 10:00', 'Machine Learning', 'Room 301', Colors.blue),
                  _buildScheduleItem('10:15 - 11:15', 'Data Structures', 'Room 205', Colors.green),
                  _buildScheduleItem('11:30 - 12:30', 'Database Systems', 'Lab 1', Colors.orange),
                  _buildScheduleItem('2:00 - 3:00', 'Software Engineering', 'Room 401', Colors.purple),
                ],
              ),
            ),
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
                'View Attendance',
                Icons.check_circle,
                Colors.indigo,
                () => _tabController.animateTo(1),
              ),
              _buildActionCard(
                'Check Schedule',
                Icons.schedule,
                Colors.blue,
                () => _tabController.animateTo(2),
              ),
              _buildActionCard(
                'Assignments',
                Icons.assignment,
                Colors.green,
                () => _tabController.animateTo(3),
              ),
              _buildActionCard(
                'Performance',
                Icons.analytics,
                Colors.orange,
                () => _tabController.animateTo(5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.indigo,
                    backgroundImage: _currentStudent?.photo.isNotEmpty == true
                        ? NetworkImage(_currentStudent!.photo)
                        : null,
                    child: _currentStudent?.photo.isEmpty != false
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentStudent?.name ?? 'Student Name',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Roll No: ${_currentStudent?.rollNumber ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentStudent != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentProfileEditPage(student: _currentStudent!),
                          ),
                        ).then((_) => _loadStudentData());
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Personal Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_currentStudent != null) ...[
                    _buildInfoRow('Email', _currentStudent!.email),
                    _buildInfoRow('Department', _currentStudent!.department),
                    _buildInfoRow('Year', _currentStudent!.year),
                    _buildInfoRow('Section', _currentStudent!.section),
                    _buildInfoRow('Phone', _currentStudent!.phoneNumber),
                    _buildInfoRow('Parent Contact', _currentStudent!.parentContact),
                    _buildInfoRow('Date of Birth', '${_currentStudent!.dateOfBirth.day}/${_currentStudent!.dateOfBirth.month}/${_currentStudent!.dateOfBirth.year}'),
                    _buildInfoRow('Address', _currentStudent!.address),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Academic Performance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Academic Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPerformanceCard(
                          'Current GPA',
                          '${_dashboardStats['gpa']?.toStringAsFixed(2) ?? '0.00'}',
                          Icons.star,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPerformanceCard(
                          'Class Rank',
                          '${_dashboardStats['rank'] ?? 0}',
                          Icons.trending_up,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Subject-wise Performance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._buildSubjectPerformanceList(),
                ],
              ),
            ),
          ),
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

  Widget _buildScheduleItem(String time, String subject, String room, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$time • $room',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSubjectPerformanceList() {
    Map<String, SubjectAttendance> subjectWiseAttendance = 
        _dashboardStats['subjectWiseAttendance'] as Map<String, SubjectAttendance>? ?? {};
    
    if (subjectWiseAttendance.isEmpty) {
      // Show default subjects if no real data is available
      return [
        _buildSubjectPerformance('Machine Learning', 8.5, 92),
        _buildSubjectPerformance('Data Structures', 7.8, 88),
        _buildSubjectPerformance('Database Systems', 8.2, 85),
        _buildSubjectPerformance('Software Engineering', 8.0, 90),
        _buildSubjectPerformance('Computer Networks', 7.5, 82),
        _buildSubjectPerformance('Operating Systems', 8.3, 87),
      ];
    }
    
    // Build performance widgets from real attendance data
    return subjectWiseAttendance.entries.map((entry) {
      String subject = entry.key;
      SubjectAttendance attendance = entry.value;
      
      // Generate mock grades for demonstration (in a real app, this would come from grades service)
      double mockGrade = _generateMockGrade(attendance.percentage);
      
      return _buildSubjectPerformance(subject, mockGrade, attendance.percentage.round());
    }).toList();
  }

  double _generateMockGrade(double attendancePercentage) {
    // Generate a mock grade based on attendance percentage
    // This is just for demonstration - in a real app, grades would come from a separate service
    if (attendancePercentage >= 90) return 8.5 + (attendancePercentage - 90) / 10 * 1.5;
    if (attendancePercentage >= 80) return 8.0 + (attendancePercentage - 80) / 10 * 0.5;
    if (attendancePercentage >= 70) return 7.0 + (attendancePercentage - 70) / 10 * 1.0;
    if (attendancePercentage >= 60) return 6.0 + (attendancePercentage - 60) / 10 * 1.0;
    return 5.0 + attendancePercentage / 60 * 1.0;
  }

  Widget _buildSubjectPerformance(String subject, double grade, int attendance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Grade: ${grade.toStringAsFixed(1)}',
                style: TextStyle(
                  color: grade >= 8.0 ? Colors.green : grade >= 7.0 ? Colors.orange : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: attendance / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    attendance >= 85 ? Colors.green : attendance >= 75 ? Colors.orange : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$attendance%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
