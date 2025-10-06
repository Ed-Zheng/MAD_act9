import 'package:flutter/material.dart';
import 'pumpkin_game_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pumpkin Game',
      home: const PumpkinGamePage(), // starts at level 1
    );
  }
}