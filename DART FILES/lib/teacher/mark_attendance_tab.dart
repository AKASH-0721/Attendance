import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'attendance_grid.dart';
import 'api_service.dart';

class MarkAttendanceTab extends StatefulWidget {
  const MarkAttendanceTab({super.key});

  @override
  State<MarkAttendanceTab> createState() => _MarkAttendanceTabState();
}

class _MarkAttendanceTabState extends State<MarkAttendanceTab> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  String selectedSection = "A";
  Map<int, bool> attendance = {};

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAttendance();
  }

  void _initializeAttendance() {
    attendance.clear();
    int start = selectedSection == "A"
        ? 1
        : selectedSection == "B"
        ? 65
        : 128;
    int end = selectedSection == "A"
        ? 64
        : selectedSection == "B"
        ? 127
        : 200;
    for (var i = start; i <= end; i++) attendance[i] = false;
    setState(() {});
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final rawImage = await _controller!.takePicture();
    setState(() => _capturedImage = rawImage);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _capturedImage = XFile(picked.path));
  }

  Future<void> _recognizeFaces() async {
    if (_capturedImage == null) return;
    try {
      final file = File(_capturedImage!.path);
      final res = await ApiService.recognizeFace(file);
      if (res['marked_rolls'] != null) {
        for (var roll in res['marked_rolls']) {
          if (attendance.containsKey(roll)) attendance[roll] = true;
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Attendance updated")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _toggleRoll(int roll) {
    setState(() => attendance[roll] = !(attendance[roll] ?? false));
  }

  void _saveAttendance() async {
    List<int> presentRolls = [];
    attendance.forEach((roll, present) {
      if (present) presentRolls.add(roll);
    });
    try {
      final res = await ApiService.saveAttendance(
        presentRolls,
        selectedSection,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Attendance saved")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error saving attendance")));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Section toggle buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ["A", "B", "C", "All"].map((sec) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedSection == sec
                    ? Colors.blue
                    : Colors.grey,
              ),
              onPressed: () {
                selectedSection = sec;
                _initializeAttendance();
              },
              child: Text(sec),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Camera preview or selected image
        Expanded(
          child: _capturedImage == null
              ? CameraPreview(_controller!)
              : Image.file(File(_capturedImage!.path), fit: BoxFit.contain),
        ),
        const SizedBox(height: 10),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text("Capture"),
            ),
            ElevatedButton(onPressed: _pickImage, child: const Text("Upload")),
            ElevatedButton(
              onPressed: _recognizeFaces,
              child: const Text("Recognize"),
            ),
            ElevatedButton(
              onPressed: _saveAttendance,
              child: const Text("Save"),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Attendance Grid
        Expanded(
          child: AttendanceGrid(attendance: attendance, onToggle: _toggleRoll),
        ),
      ],
    );
  }
}
