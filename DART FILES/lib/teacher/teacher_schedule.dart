import 'package:flutter/material.dart';
import '../models/teacher_model.dart';

class TeacherSchedulePage extends StatefulWidget {
  final Teacher? teacher;

  const TeacherSchedulePage({super.key, this.teacher});

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final List<String> _timeSlots = [
    '9:00 - 10:00',
    '10:00 - 11:00',
    '11:15 - 12:15',
    '12:15 - 1:15',
    '2:00 - 3:00',
    '3:00 - 4:00',
    '4:00 - 5:00',
  ];

  // Sample schedule data - In real app, this would come from database
  Map<String, Map<String, String>> _schedule = {};

  @override
  void initState() {
    super.initState();
    _generateSampleSchedule();
  }

  void _generateSampleSchedule() {
    if (widget.teacher?.classes != null) {
      // Generate a sample schedule based on teacher's classes
      final classes = widget.teacher!.classes;
      int classIndex = 0;
      
      for (int dayIndex = 0; dayIndex < _weekDays.length && dayIndex < 5; dayIndex++) {
        final day = _weekDays[dayIndex];
        _schedule[day] = {};
        
        // Assign 2-3 classes per day
        for (int slotIndex = 0; slotIndex < _timeSlots.length && slotIndex < 3; slotIndex++) {
          if (classIndex < classes.length) {
            _schedule[day]![_timeSlots[slotIndex]] = classes[classIndex];
            classIndex = (classIndex + 1) % classes.length;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.teacher == null
          ? const Center(child: Text('No teacher data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.indigo, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weekly Schedule',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Current week schedule for ${widget.teacher!.name}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Schedule Table
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Header Row
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                ..._weekDays.take(5).map((day) => Expanded(
                                  child: Text(
                                    day.substring(0, 3),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Schedule Rows
                          ..._timeSlots.map((timeSlot) => _buildScheduleRow(timeSlot)).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Today's Classes
                  _buildTodaysClasses(),
                  const SizedBox(height: 20),

                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildScheduleRow(String timeSlot) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              timeSlot,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          ..._weekDays.take(5).map((day) {
            final className = _schedule[day]?[timeSlot];
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: className != null ? Colors.indigo.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(4),
                  border: className != null ? Border.all(color: Colors.indigo.withOpacity(0.3)) : null,
                ),
                child: Text(
                  className ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: className != null ? FontWeight.w500 : FontWeight.normal,
                    color: className != null ? Colors.indigo : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTodaysClasses() {
    final today = DateTime.now().weekday;
    final todayName = _weekDays[today - 1];
    final todaysClasses = _schedule[todayName] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Classes ($todayName)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todaysClasses.isEmpty)
              const Text(
                'No classes scheduled for today',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...todaysClasses.entries.map((entry) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: Icon(Icons.class_, color: Colors.green),
                ),
                title: Text(entry.value),
                subtitle: Text(entry.key),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to class details or attendance marking
                },
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildQuickActionButton(
                  'Add Class',
                  Icons.add,
                  Colors.blue,
                  () {
                    // TODO: Implement add class functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add class feature coming soon!')),
                    );
                  },
                ),
                _buildQuickActionButton(
                  'Edit Schedule',
                  Icons.edit,
                  Colors.orange,
                  () {
                    // TODO: Implement edit schedule functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit schedule feature coming soon!')),
                    );
                  },
                ),
                _buildQuickActionButton(
                  'View Calendar',
                  Icons.calendar_today,
                  Colors.green,
                  () {
                    // TODO: Implement calendar view
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calendar view coming soon!')),
                    );
                  },
                ),
                _buildQuickActionButton(
                  'Export Schedule',
                  Icons.download,
                  Colors.purple,
                  () {
                    // TODO: Implement export functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}