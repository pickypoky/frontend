import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_final.dart'; // DiaryDetailScreen import

class DiaryScreen extends StatefulWidget {
  final DateTime selectedDay;

  const DiaryScreen({super.key, required this.selectedDay});

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _diaryController = TextEditingController();
  String _diaryContent = '';

  DateTime get _currentDay => widget.selectedDay;

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  Future<void> _loadDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);
    setState(() {
      _diaryContent = prefs.getString(diaryKey) ?? '';
      _diaryController.text = _diaryContent;
    });
  }

  Future<void> _saveDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);

    if (_diaryController.text.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기 내용은 최소 15자 이상 작성해야 합니다.')),
      );
      return;
    }

    if (_diaryController.text.isNotEmpty) {
      await prefs.setString(diaryKey, _diaryController.text);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일기가 저장되었습니다.')),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          selectedDay: _currentDay,
          diaryContent: _diaryController.text,
          // 이모지 파라미터 제거
        ),
      ),
    );
  }

  void _changeDate(int days) {
    final newDate = _currentDay.add(Duration(days: days));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryScreen(selectedDay: newDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // 뒤로 가기
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDate(-1),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd').format(_currentDay),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDate(1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '당신의 이야기를 기록해보세요',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Container(
              constraints: BoxConstraints(
                maxHeight: 350.0, // 텍스트 상자의 최대 높이
              ),
              child: TextField(
                controller: _diaryController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '무엇이든 자유롭게 적어보세요',
                ),
                expands: false,
                minLines: 6, // 최소 줄 수
              ),
            ),
            const SizedBox(height: 10.0),
            Center(
              child: ElevatedButton(
                onPressed: _saveDiary,
                child: const Text('작성 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
