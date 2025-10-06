import 'package:flutter/material.dart';
import 'pick_pumpkin_page.dart';

void main() {
  runApp(HalloweenStorybookApp());
}

class HalloweenStorybookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Halloween Storybook',
      theme: ThemeData.dark(),
      home: PickPumpkinPage(),
    );
  }
}