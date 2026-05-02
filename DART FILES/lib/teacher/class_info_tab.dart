import 'package:flutter/material.dart';
import '../models/teacher_model.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import 'class_details_page.dart';

class ClassInfoTab extends StatefulWidget {
  const ClassInfoTab({super.key});

  @override
  State<ClassInfoTab> createState() => _ClassInfoTabState();
}

class _ClassInfoTabState extends State<ClassInfoTab> {
  final AuthService _authService = AuthService();
  final StudentService _studentService = StudentService();
  
  Teacher? _currentTeacher;
  Map<String, Map<String, dynamic>> _classesData = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  
  final List<String> _filters = ['All', 'Today', 'This Week', 'High Attendance', 'Low Attendance'];

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  Future<void> _loadTeacherClasses() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final teacher = await _authService.getTeacherData(user.uid);
        if (teacher != null) {
          final classesData = await _loadClassesDetails(teacher);
          setState(() {
            _currentTeacher = teacher;
            _classesData = classesData;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load classes: ${e.toString()}');
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadClassesDetails(Teacher teacher) async {
    Map<String, Map<String, dynamic>> classesData = {};
    
    for (String className in teacher.classes) {
      try {
        // Extract section from class name (e.g., "AI & DS A" -> "A")
        String section = className.split(' ').last;
        final students = await _studentService.getStudentsBySection(section);
        
        // Generate sample data for demonstration
        classesData[className] = {
          'students': students,
          'totalStudents': students.length,
          'presentToday': (students.length * 0.85).round(),
          'absentToday': (students.length * 0.15).round(),
          'averageAttendance': 85.5 + (className.hashCode % 10),
          'room': _getRoomForClass(className),
          'timing': _getTimingForClass(className),
          'subject': _getSubjectForClass(className),
          'building': _getBuildingForClass(className),
          'nextClass': _getNextClassTime(className),
          'totalClasses': 45,
          'classesHeld': 42,
        };
      } catch (e) {
        // Fallback data if student service fails
        classesData[className] = {
          'students': [],
          'totalStudents': 60,
          'presentToday': 51,
          'absentToday': 9,
          'averageAttendance': 85.0,
          'room': _getRoomForClass(className),
          'timing': _getTimingForClass(className),
          'subject': _getSubjectForClass(className),
          'building': _getBuildingForClass(className),
          'nextClass': _getNextClassTime(className),
          'totalClasses': 45,
          'classesHeld': 42,
        };
      }
    }
    
    return classesData;
  }

  String _getRoomForClass(String className) {
    final rooms = ['Room 301', 'Room 205', 'Lab 1', 'Room 401', 'Lab 2', 'Room 302'];
    return rooms[className.hashCode % rooms.length];
  }

  String _getTimingForClass(String className) {
    final timings = ['9:00 - 10:00', '10:15 - 11:15', '11:30 - 12:30', '2:00 - 3:00', '3:15 - 4:15'];
    return timings[className.hashCode % timings.length];
  }

  String _getSubjectForClass(String className) {
    if (className.contains('AI & DS')) return 'Machine Learning';
    if (className.contains('CSE')) return 'Data Structures';
    if (className.contains('ECE')) return 'Digital Electronics';
    if (className.contains('ME')) return 'Thermodynamics';
    if (className.contains('EEE')) return 'Circuit Analysis';
    return 'Computer Science';
  }

  String _getBuildingForClass(String className) {
    final buildings = ['Block A', 'Block B', 'Block C', 'Lab Block', 'Main Block'];
    return buildings[className.hashCode % buildings.length];
  }

  String _getNextClassTime(String className) {
    final nextTimes = ['Tomorrow 9:00 AM', 'Today 2:00 PM', 'Tomorrow 10:15 AM', 'Friday 11:30 AM'];
    return nextTimes[className.hashCode % nextTimes.length];
  }

  List<String> get _filteredClasses {
    List<String> classes = _currentTeacher?.classes ?? [];
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      classes = classes.where((className) =>
        className.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        _getSubjectForClass(className).toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply category filter
    if (_selectedFilter != 'All') {
      classes = classes.where((className) {
        final classData = _classesData[className];
        if (classData == null) return false;
        
        switch (_selectedFilter) {
          case 'Today':
            return _hasClassToday(className);
          case 'This Week':
            return _hasClassThisWeek(className);
          case 'High Attendance':
            return (classData['averageAttendance'] ?? 0) >= 85;
          case 'Low Attendance':
            return (classData['averageAttendance'] ?? 0) < 75;
          default:
            return true;
        }
      }).toList();
    }
    
    return classes;
  }

  bool _hasClassToday(String className) {
    // Sample logic - in real app, check actual schedule
    return className.hashCode % 3 == 0;
  }

  bool _hasClassThisWeek(String className) {
    // Sample logic - in real app, check actual schedule
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentTeacher == null || _currentTeacher!.classes.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search and filters
          _buildHeader(),
          const SizedBox(height: 20),

          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 20),

          // Classes Grid
          _buildClassesGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.class_, color: Colors.indigo, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'My Classes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadTeacherClasses,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search classes or subjects...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: Colors.indigo.withOpacity(0.2),
                      checkmarkColor: Colors.indigo,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalClasses = _currentTeacher?.classes.length ?? 0;
    final totalStudents = _classesData.values.fold(0, (sum, data) => sum + (data['totalStudents'] as int? ?? 0));
    final averageAttendance = _classesData.values.isEmpty ? 0.0 : 
        _classesData.values.fold(0.0, (sum, data) => sum + (data['averageAttendance'] as double? ?? 0.0)) / _classesData.values.length;
    final classesToday = _filteredClasses.where(_hasClassToday).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Classes',
            totalClasses.toString(),
            Icons.class_,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Students',
            totalStudents.toString(),
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Avg. Attendance',
            '${averageAttendance.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Today\'s Classes',
            classesToday.toString(),
            Icons.today,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesGrid() {
    final filteredClasses = _filteredClasses;
    
    if (filteredClasses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No classes found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredClasses.length,
      itemBuilder: (context, index) {
        final className = filteredClasses[index];
        final classData = _classesData[className]!;
        return _buildClassCard(className, classData);
      },
    );
  }

  Widget _buildClassCard(String className, Map<String, dynamic> classData) {
    final attendancePercentage = classData['averageAttendance'] as double;
    final attendanceColor = _getAttendanceColor(attendancePercentage);
    
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailsPage(
                className: className,
                classData: classData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      className,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: attendanceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${attendancePercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: attendanceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Subject
              Text(
                classData['subject'],
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              
              // Students Info
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${classData['totalStudents']} students',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Location Info
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${classData['room']} • ${classData['building']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Timing Info
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    classData['timing'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Today's Attendance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Today: ${classData['presentToday']}/${classData['totalStudents']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Next: ${classData['nextClass']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Classes Assigned',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your administrator to get classes assigned to your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTeacherClasses,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }
}
