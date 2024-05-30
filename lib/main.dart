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
  int? hoverIdx;
  int? dragIdx;

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

  void _updateNote(index, content) {
    setState(() {
      _notes[index] = Note('', content);
    });
    _saveNotes();
  }

  void _deleteNote(index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveNotes();
  }

  void _reorderNotes(fromIndex, toIndex) {
    setState(() {
      if (fromIndex != toIndex) {
        var noteToMove = _notes.removeAt(fromIndex);
        _notes.insert(toIndex, noteToMove);
      }
      dragIdx = null;
      hoverIdx = null;
    });
    if (fromIndex != toIndex) {
      _saveNotes();
    }
  }

  Future<void> _openNote(context, index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContentScreen(),
        settings: RouteSettings(
          arguments: _notes[index],
        ),
      ),
    );
    if (!context.mounted) return;
    if (result == '' || (result == null && _notes[index].content == '')) {
      _deleteNote(index);
    } else if (result != null) {
      _updateNote(index, result);
    }
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
      ),
      backgroundColor: Colors.grey.shade100,
      body: ListView.builder(
        key: UniqueKey(),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          var content = _notes[index].content;
          content = (content.length > 20) ? '${content.substring(0, 20)}...' : content;
          return DragTarget<int>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                padding: const EdgeInsets.all(2.0),
                margin: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: (index == hoverIdx && dragIdx != hoverIdx)
                    ? (dragIdx! < hoverIdx!)
                      ? const Border(bottom: BorderSide(color: Colors.black, width: 10))
                      : const Border(top: BorderSide(color: Colors.black, width: 10))
                    : (index == dragIdx)
                      ? null
                      : Border.all(color: Colors.grey.shade700),
                  borderRadius: const BorderRadius.all(Radius.circular(7.0)),
                ),
                child: LongPressDraggable<int>(
                  data: index,
                  feedback: const DragItem(),
                  dragAnchorStrategy: childDragAnchorStrategy,
                  child: ListTile(
                    title: Text((index == dragIdx) ? '' : content),
                    onTap: () {
                      _openNote(context, index);
                    },
                  ),
                  onDragStarted: () {
                    setState(() {
                      dragIdx = index;
                    });
                  },
                ),
              );
            },
            onWillAcceptWithDetails: (details) {
              if (hoverIdx != index) {
                setState(() {
                  hoverIdx = index;
                });
              }
              return true;
            },
            onAcceptWithDetails: (details) {
              _reorderNotes(details.data, index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNote(const Note('', ''));
          _openNote(context, 0);
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {

  final TextEditingController _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final note = ModalRoute.of(context)!.settings.arguments as Note;
    _controller.value = _controller.value.copyWith(
      text: note.content,
      // selection: TextSelection.collapsed(offset: 0),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: (){
              Navigator.pop(context, _controller.value.text);
            },
            icon: const Icon(Icons.check, color: Colors.white),
          ),
          IconButton(
            onPressed: (){
              Navigator.pop(context, '');
            },
            icon: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          // autofocus: true,
          expands: true,
          decoration: const InputDecoration( border: InputBorder.none ),
          minLines: null,
          maxLines: null,
          controller: _controller
        ),
      ),
    );
  }
}

class DragItem extends StatelessWidget {
  const DragItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50.0,
      color: Colors.grey.withOpacity(0.4),
    );
  }
}
