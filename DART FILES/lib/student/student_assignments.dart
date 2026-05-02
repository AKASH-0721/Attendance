import 'package:flutter/material.dart';
import '../models/student_model.dart';

class StudentAssignmentsPage extends StatefulWidget {
  final Student? student;

  const StudentAssignmentsPage({super.key, this.student});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Submitted', 'Overdue'];

  // Sample assignments data
  final List<Map<String, dynamic>> _assignments = [
    {
      'id': '1',
      'title': 'Machine Learning Project',
      'subject': 'Machine Learning',
      'description': 'Implement a neural network for image classification',
      'dueDate': DateTime.now().add(const Duration(days: 7)),
      'status': 'Pending',
      'priority': 'High',
      'marks': 100,
      'submittedDate': null,
    },
    {
      'id': '2',
      'title': 'Database Design Assignment',
      'subject': 'Database Systems',
      'description': 'Design a normalized database for e-commerce system',
      'dueDate': DateTime.now().add(const Duration(days: 3)),
      'status': 'Pending',
      'priority': 'Medium',
      'marks': 50,
      'submittedDate': null,
    },
    {
      'id': '3',
      'title': 'Data Structures Implementation',
      'subject': 'Data Structures',
      'description': 'Implement binary search tree with all operations',
      'dueDate': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'Submitted',
      'priority': 'High',
      'marks': 75,
      'submittedDate': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'id': '4',
      'title': 'Software Engineering Report',
      'subject': 'Software Engineering',
      'description': 'Write a report on Agile development methodologies',
      'dueDate': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'Overdue',
      'priority': 'High',
      'marks': 60,
      'submittedDate': null,
    },
    {
      'id': '5',
      'title': 'Network Security Analysis',
      'subject': 'Computer Networks',
      'description': 'Analyze common network security vulnerabilities',
      'dueDate': DateTime.now().add(const Duration(days: 14)),
      'status': 'Pending',
      'priority': 'Low',
      'marks': 40,
      'submittedDate': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredAssignments {
    if (_selectedFilter == 'All') return _assignments;
    return _assignments.where((assignment) => assignment['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filter
            _buildHeader(),
            const SizedBox(height: 20),

            // Summary Cards
            _buildSummaryCards(),
            const SizedBox(height: 20),

            // Assignments List
            _buildAssignmentsList(),
          ],
        ),
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
                Icon(Icons.assignment, color: Colors.indigo, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Assignments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
    final pendingCount = _assignments.where((a) => a['status'] == 'Pending').length;
    final submittedCount = _assignments.where((a) => a['status'] == 'Submitted').length;
    final overdueCount = _assignments.where((a) => a['status'] == 'Overdue').length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard('Pending', pendingCount.toString(), Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard('Submitted', submittedCount.toString(), Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard('Overdue', overdueCount.toString(), Colors.red),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count,
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
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignments (${_filteredAssignments.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._filteredAssignments.map((assignment) => _buildAssignmentCard(assignment)).toList(),
      ],
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final status = assignment['status'];
    final priority = assignment['priority'];
    final dueDate = assignment['dueDate'] as DateTime;
    final isOverdue = status == 'Overdue';
    final isPending = status == 'Pending';
    final isSubmitted = status == 'Submitted';

    Color statusColor = Colors.grey;
    if (isOverdue) statusColor = Colors.red;
    if (isPending) statusColor = Colors.orange;
    if (isSubmitted) statusColor = Colors.green;

    Color priorityColor = Colors.grey;
    if (priority == 'High') priorityColor = Colors.red;
    if (priority == 'Medium') priorityColor = Colors.orange;
    if (priority == 'Low') priorityColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              assignment['subject'],
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              assignment['description'],
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Due: ${_formatDate(dueDate)}',
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.grey[600],
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.flag, size: 16, color: priorityColor),
                const SizedBox(width: 4),
                Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${assignment['marks']} marks',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (assignment['submittedDate'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted: ${_formatDate(assignment['submittedDate'])}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _submitAssignment(assignment),
                      icon: const Icon(Icons.upload),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewAssignmentDetails(assignment),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _submitAssignment(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submit ${assignment['title']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose submission method:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.file_upload),
              title: Text('Upload File'),
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Submit Link'),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Text Submission'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignment submission feature coming soon!')),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _viewAssignmentDetails(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Subject', assignment['subject']),
              _buildDetailRow('Description', assignment['description']),
              _buildDetailRow('Due Date', _formatDate(assignment['dueDate'])),
              _buildDetailRow('Priority', assignment['priority']),
              _buildDetailRow('Marks', '${assignment['marks']}'),
              _buildDetailRow('Status', assignment['status']),
              if (assignment['submittedDate'] != null)
                _buildDetailRow('Submitted', _formatDate(assignment['submittedDate'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}