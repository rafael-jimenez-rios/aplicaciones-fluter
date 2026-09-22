import 'package:flutter/material.dart';
import 'ui/screens/check_session_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fake Store Auth App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CheckSessionScreen(),
    );
  }
}