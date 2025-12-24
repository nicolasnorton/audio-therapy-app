import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/web_library_message.dart';

import 'package:flutter/material.dart';

import '../screens/therapy_home_page.dart';
import '../screens/library_page.dart';
import '../widgets/web_library_message.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const TherapyHomePage(),
      kIsWeb ? const WebLibraryMessage() : const LibraryPage(),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Create'),
            NavigationDestination(icon: Icon(Icons.library_music), label: 'Library'),
          ],
        ),
      );
}