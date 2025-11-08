import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ApiService {
  static const String baseUrl = "http://10.201.13.42:5000";

  static Future<Map<String, dynamic>> recognizeFace(File file) async {
    final uri = Uri.parse("$baseUrl/recognize");
    var request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: basename(file.path),
      ),
    );
    var response = await request.send();

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      return jsonDecode(respStr);
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> saveAttendance(
    List<int> rolls,
    String section,
  ) async {
    final uri = Uri.parse("$baseUrl/mark_manual");
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"rolls": rolls, "section": section}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error saving attendance");
    }
  }
}
