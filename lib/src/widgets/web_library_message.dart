import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class WebLibraryMessage extends StatelessWidget {
  const WebLibraryMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library'), centerTitle: true),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_download, size: 80, color: Colors.white54),
            SizedBox(height: 20),
            Text('Tracks are downloaded!', style: TextStyle(fontSize: 20)),
            Text('Check your Downloads folder', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}