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
  List<String> _existingDiaries = [];

  DateTime get _currentDay => widget.selectedDay;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);

    final List<String> diaries = prefs.getStringList(diaryKey) ?? [];
    setState(() {
      _existingDiaries = diaries;
    });
  }

  Future<void> _saveDiary(String content) async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);

    // 현재 작성된 일기 개수 가져오기
    final List<String> diaries = prefs.getStringList(diaryKey) ?? [];
    if (diaries.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('하루에 작성할 수 있는 일기 개수는 3개까지입니다.')),
      );
      return;
    }

    if (content.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기 내용은 최소 15자 이상 작성해야 합니다.')),
      );
      return;
    }

    if (content.isNotEmpty) {
      diaries.add(content);
      await prefs.setStringList(diaryKey, diaries);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기가 저장되었습니다.')),
      );

      setState(() {
        _existingDiaries = diaries;
      });

      Navigator.of(context).pop(); // Return to the previous screen
    }
  }

  Future<void> _deleteDiary(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);

    setState(() {
      _existingDiaries.removeAt(index);
    });

    await prefs.setStringList(diaryKey, _existingDiaries);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일기가 삭제되었습니다.')),
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

  void _navigateToDiaryCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryCreationScreen(
          onSave: _saveDiary,
        ),
      ),
    ).then((_) {
      // Reload diaries after returning from DiaryCreationScreen
      _loadDiaries();
    });
  }

  void _viewDiaryDetail(String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(content: content),
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
            if (_existingDiaries.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 여백 추가
                  itemCount: _existingDiaries.length,
                  itemBuilder: (context, index) {
                    final diary = _existingDiaries[index];
                    final preview = diary.length > 20 ? '${diary.substring(0, 20)}...' : diary;
                    return Dismissible(
                      key: Key('$diary$index'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteDiary(index);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () => _viewDiaryDetail(diary),
                        child: Container(
                          width: double.infinity, // 가로 길이를 부모 위젯에 맞게 설정
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(16.0),
                          height: 100.0, // 박스의 높이를 100.0으로 설정
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preview,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10.0),
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToDiaryCreation,
                  child: const Text('일기 작성'),
                ),
              ),
            ] else ...[
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
                  onPressed: () {
                    _saveDiary(_diaryController.text);
                  },
                  child: const Text('작성 완료'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DiaryCreationScreen extends StatefulWidget {
  final Future<void> Function(String content) onSave;

  const DiaryCreationScreen({super.key, required this.onSave});

  @override
  _DiaryCreationScreenState createState() => _DiaryCreationScreenState();
}

class _DiaryCreationScreenState extends State<DiaryCreationScreen> {
  final TextEditingController _diaryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 일기 작성'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onSave(_diaryController.text);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '당신의 이야기를 기록해보세요',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
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
                onPressed: () {
                  widget.onSave(_diaryController.text);
                },
                child: const Text('작성 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiaryDetailScreen extends StatelessWidget {
  final String content;

  const DiaryDetailScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 상세보기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(fontSize: 16.0),
          ),
        ),
      ),
    );
  }
}
