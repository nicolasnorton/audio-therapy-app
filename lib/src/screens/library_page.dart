import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final AudioPlayer _player = AudioPlayer();
  List<File> tracks = [];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.wav')).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      setState(() => tracks = files);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Library load error: $e')));
    }
  }

  Future<void> _playTrack(File file) async {
    try {
      await _player.setFilePath(file.path);
      await _player.play();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback error: $e')));
    }
  }

  Future<void> _deleteTrack(File file) async {
    try {
      await file.delete();
      await _loadTracks();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Track deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete error: $e')));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Library'), centerTitle: true),
      body: tracks.isEmpty
          ? const Center(child: Text('No tracks yet.\nGenerate some!', textAlign: TextAlign.center))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (_, i) {
                final file = tracks[i];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.teal),
                  title: Text(path.basename(file.path)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteTrack(file),
                  ),
                  onTap: () => _playTrack(file),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: _loadTracks,
      ),
    );
  }
}