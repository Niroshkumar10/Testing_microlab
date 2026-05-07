import 'package:flutter/material.dart';
import './modules/student_page.dart';
import '../utils/storage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void logout(BuildContext context) async {
    await Storage.clearToken();

    Navigator.pushReplacementNamed(
      context,
      "/login",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),

      // Student Module Integration
      body: const StudentPage(),
    );
  }
}