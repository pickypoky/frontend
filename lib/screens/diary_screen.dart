import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryScreen extends StatefulWidget {
  final DateTime selectedDay;

  const DiaryScreen({super.key, required this.selectedDay});

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _diaryController = TextEditingController();
  String _diaryContent = '';
  String _selectedEmoji = '';

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  Future<void> _loadDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    setState(() {
      _diaryContent = prefs.getString(diaryKey) ?? '';
      _diaryController.text = _diaryContent;
    });
  }

  Future<void> _saveDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(widget.selectedDay);

    if (_diaryController.text.isNotEmpty) {
      await prefs.setString(diaryKey, _diaryController.text);
    }

    await prefs.setString('${diaryKey}_emoji', _selectedEmoji);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diary saved')),
    );
  }

  Future<void> _selectEmoji() async {
    // Implement a dialog or a widget to select an emoji
    String? emoji = await showDialog(
      context: context,
      builder: (context) => EmojiPickerDialog(selectedEmoji: _selectedEmoji),
    );

    if (emoji != null) {
      setState(() {
        _selectedEmoji = emoji;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diary for ${DateFormat('yyyy-MM-dd').format(widget.selectedDay)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDiary,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _diaryController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write your diary here...',
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text('Selected Emoji: $_selectedEmoji'),
            ElevatedButton(
              onPressed: _selectEmoji,
              child: const Text('Select Emoji'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmojiPickerDialog extends StatelessWidget {
  final String selectedEmoji;

  const EmojiPickerDialog({super.key, required this.selectedEmoji});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Emoji'),
      content: GridView.count(
        crossAxisCount: 5,
        children: [
          '😊', '😂', '😢', '😡', '😍', // Add more emojis as needed
        ].map((emoji) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pop(emoji);
            },
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24.0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
