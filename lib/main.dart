import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Note {
  final String title;
  final String content;

  const Note(this.title, this.content);
}

const String storeKey = "NOTES";

void main() {
  runApp(
    const MaterialApp(
      title: 'Notes',
      home: SafeArea(child: ListScreen()),
    ),
  );
}

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Note> _notes = List.empty();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _addNote(Note note) {
    setState(() {
      _notes.insert(0, note);
    });
    _saveNotes();
  }

  void _openNote(context, index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContentScreen(),
        settings: RouteSettings(
          arguments: _notes[index],
        ),
      ),
    );
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notes = (prefs.getStringList(storeKey) ?? List.empty()).map((content) => Note('', content)).toList();
      debugPrint('loaded ${_notes.length}');
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('saving ${_notes.length}');
    prefs.setStringList(storeKey, _notes.map((note) => note.content).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        // title: const Text(''),
      ),
      backgroundColor: Colors.grey.shade100,
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          debugPrint('build $index');
          var content = _notes[index].content;
          content = (content.length > 20) ? '${content.substring(0, 20)}...' : content;
          return Container(
            padding: const EdgeInsets.all(2.0),
            margin: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: const BorderRadius.all(Radius.circular(7.0)),
            ),
            child: ListTile(
              title: Text(content),
              onTap: () {
                _openNote(context, index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNote(Note('', 'Content for Note ${_notes.length}'));
          _openNote(context, 0);
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final note = ModalRoute.of(context)!.settings.arguments as Note;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        // title: Text(''),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(note.content),
      ),
    );
  }
}
