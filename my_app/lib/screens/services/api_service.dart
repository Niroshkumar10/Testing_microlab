import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  
  // ✅ Dynamic URL — auto switches based on platform
  // static String get baseUrl {
  //   if (kIsWeb) {
  //     return "http://localhost:5000/api";        // Flutter Web
  //   } else {
  //     return "http://172.16.0.105:5000/api";     // 🔴 Replace with YOUR PC IP
  //   }
  // }

  static String get baseUrl {
  if (kIsWeb) {
    return "http://localhost:5000/api";
  } else {
    return "http://localhost:5000/api"; // ✅ same for mobile via adb reverse
  }
}

  static String get authUrl    => "$baseUrl/auth";
  static String get studentUrl => "$baseUrl/students";

  // 🔐 Register
  static Future register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$authUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print("❌ Register Error: $e");
      return null;
    }
  }

  // 🔓 Login
static Future login(String email, String password) async {
  try {
    print("🌐 Trying to connect: $authUrl/login"); // ✅ add this

    final res = await http.post(
      Uri.parse("$authUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    ).timeout(Duration(seconds: 10)); // ✅ add timeout — stops infinite loading

    print("📥 Login Status: ${res.statusCode}");
    print("📥 Login Body: ${res.body}");

    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  } catch (e) {
    print("❌ Login Error: $e"); // ✅ this will tell us exactly what's wrong
    return null;
  }
}

  // 📋 Get Students
  static Future getStudents() async {
    try {
      final token = await Storage.getToken();
      if (token == null) return [];

      final res = await http.get(
        Uri.parse(studentUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print("❌ Get Students Error: $e");
      return [];
    }
  }

  // ➕ Add Student
  // static Future addStudent(String name, String age, String dept) async {
  //   try {
  //     final token = await Storage.getToken();
  //     if (token == null) return null;

  //     final res = await http.post(
  //       Uri.parse(studentUrl),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": "Bearer $token",
  //       },
  //       body: jsonEncode({
  //         "name": name,
  //         "age": int.tryParse(age) ?? 0,
  //         "department": dept,
  //       }),
  //     );
  //     return jsonDecode(res.body);
  //   } catch (e) {
  //     print("❌ Add Student Error: $e");
  //     return null;
  //   }
  // }
  static Future addStudent(
  Map<String, dynamic> data,
) async {

  final token = await Storage.getToken();

  final response = await http.post(

    Uri.parse("$baseUrl/students"),

    headers: {

      "Content-Type": "application/json",

      "Authorization": "Bearer $token",
    },

    body: jsonEncode(data),
  );

  return jsonDecode(response.body);
}

  // 🖼️ Upload Student Profile Image (Web + Mobile)
  static Future uploadStudentImage(String studentId, dynamic imageFile) async {
    try {
      final token = await Storage.getToken();
      if (token == null) return null;

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("$studentUrl/$studentId/upload-image"),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.name ?? "upload.jpg";

      request.files.add(http.MultipartFile.fromBytes(
        'profileImage',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      print("📥 Upload Image Status: ${res.statusCode}");
      return jsonDecode(res.body);
    } catch (e) {
      print("❌ Upload Image Error: $e");
      return null;
    }
  }

  // ✏️ Update Student
  static Future updateStudent(String id, Map data) async {
    try {
      final token = await Storage.getToken();
      if (token == null) return null;

      final res = await http.put(
        Uri.parse("$studentUrl/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      print("❌ Update Student Error: $e");
      return null;
    }
  }

  // 🗑️ Delete Student
  static Future deleteStudent(String id) async {
    try {
      final token = await Storage.getToken();
      if (token == null) return;

      await http.delete(
        Uri.parse("$studentUrl/$id"),
        headers: {"Authorization": "Bearer $token"},
      );
    } catch (e) {
      print("❌ Delete Student Error: $e");
    }
  }
}