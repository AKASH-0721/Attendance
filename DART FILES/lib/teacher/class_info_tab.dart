import 'package:flutter/material.dart';

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
          DataRow(
            cells: [
              DataCell(Text('AI & DS A')),
              DataCell(Text('10:00 - 11:00')),
              DataCell(Text('Block A')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('CSE B')),
              DataCell(Text('11:00 - 12:00')),
              DataCell(Text('Block B')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('ECE C')),
              DataCell(Text('01:00 - 02:00')),
              DataCell(Text('Block C')),
            ],
          ),
        ],
      ),
    );
  }
}
