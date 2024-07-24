import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_final.dart'; // 새로운 페이지 import

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
      _selectedEmoji = prefs.getString('${diaryKey}_emoji') ?? '';
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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          selectedDay: widget.selectedDay,
          diaryContent: _diaryController.text,
          emoji: _selectedEmoji,
        ),
      ),
    );
  }

  Future<void> _selectEmoji() async {
    String? emoji = await showDialog<String>(
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
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.count(
          crossAxisCount: 5,
          children: [
            '😊', '😂', '😢', '😡', '😍',
            '🥰', '😎', '🤔', '🤩', '😴',
            '😱', '😷', '🤯', '😈', '👿',
          ].map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop(emoji);
              },
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 36.0),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
