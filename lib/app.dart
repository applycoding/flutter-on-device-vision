import 'package:flutter/material.dart';
import 'package:on_device_vision/ui/home_shell.dart';
import 'package:on_device_vision/ui/theme.dart';

class VisionApp extends StatelessWidget {
  const VisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'On-Device Vision',
      debugShowCheckedModeBanner: false,
      theme: buildVisionTheme(),
      home: const HomeShell(),
    );
  }
}
