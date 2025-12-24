import 'package:flutter/material.dart';
import 'src/screens/experience_generator_screen.dart';

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Text(
          'Error: ${details.exceptionAsString()}',
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  };

  runApp(const AuraApp());
}

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA Bio-Interface',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ExperienceGeneratorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}