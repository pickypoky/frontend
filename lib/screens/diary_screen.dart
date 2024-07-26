import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryScreen extends StatefulWidget {
  final DateTime selectedDay;
  final VoidCallback onClose;

  const DiaryScreen({super.key, required this.selectedDay, required this.onClose});

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _diaryController = TextEditingController();
  List<Map<String, String>> _existingDiaries = [];

  DateTime get _currentDay => widget.selectedDay;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);

    final List<String>? diaries = prefs.getStringList(diaryKey);
    if (diaries != null) {
      setState(() {
        _existingDiaries = diaries.map((e) {
          final parts = e.split('||');
          return {'content': parts[0], 'time': parts[1]};
        }).toList();
      });
    }
  }

  Future<void> _saveDiary(String content) async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);

    final List<String>? diaries = prefs.getStringList(diaryKey);
    if (diaries != null && diaries.length >= 3) {
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
      final newDiary = '$content||${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}';
      final updatedDiaries = [...?diaries, newDiary];

      await prefs.setStringList(diaryKey, updatedDiaries);

      setState(() {
        _existingDiaries = updatedDiaries.map((e) {
          final parts = e.split('||');
          return {'content': parts[0], 'time': parts[1]};
        }).toList();
      });

      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Return to the previous screen
        widget.onClose(); // Call onClose to switch to the calendar tab
      }
    }
  }

  Future<void> _updateDiary(int index, String updatedContent) async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);

    final List<String>? diaries = prefs.getStringList(diaryKey);
    if (diaries != null && updatedContent.isNotEmpty) {
      final parts = diaries[index].split('||');
      diaries[index] = '$updatedContent||${parts[1]}'; // Keep the original time
      await prefs.setStringList(diaryKey, diaries);

      setState(() {
        _existingDiaries = diaries.map((e) {
          final parts = e.split('||');
          return {'content': parts[0], 'time': parts[1]};
        }).toList();
      });

      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Return to the previous screen
        widget.onClose(); // Call onClose to switch to the calendar tab
      }
    }
  }

  Future<void> _deleteDiary(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(_currentDay);

    final List<String>? diaries = prefs.getStringList(diaryKey);
    if (diaries != null && index >= 0 && index < diaries.length) {
      diaries.removeAt(index);
      await prefs.setStringList(diaryKey, diaries);

      setState(() {
        _existingDiaries = diaries.map((e) {
          final parts = e.split('||');
          return {'content': parts[0], 'time': parts[1]};
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기가 삭제되었습니다.')),
      );
    }
  }

  void _changeDate(int days) {
    final newDate = _currentDay.add(Duration(days: days));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryScreen(selectedDay: newDate, onClose: widget.onClose),
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

  void _viewDiaryDetail(String content, String time, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          date: _currentDay,
          content: content,
          time: time,
          onEdit: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiaryCreationScreen(
                  initialContent: content,
                  isEditMode: true,
                  onSave: (updatedContent) async {
                    await _updateDiary(index, updatedContent);
                  },
                ),
              ),
            );
          },
          onDelete: () async {
            await _deleteDiary(index);
            Navigator.of(context).pop(); // Return to the previous screen
          },
        ),
      ),
    );
  }

  Future<void> _showCancelConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 사용자 의도치 않은 닫기 방지
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Padding(
            padding: EdgeInsets.only(top: 20.0), // 상단 여백 추가
            child: Text(
              '취소하면 작성한 내용이 사라져요.\n정말 취소할까요?',
              textAlign: TextAlign.center, // 텍스트 중앙 정렬
            ),
          ),
          actions: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 버튼들 중앙 정렬
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                    },
                    child: const Text('계속 쓸게요'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pop(); // 작성 화면 닫기
                      widget.onClose(); // Call onClose to switch to the calendar tab
                    },
                    child: const Text('취소할게요'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 자동으로 추가되는 뒤로가기 버튼 제거
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // 오른쪽 여백을 추가하여 버튼을 왼쪽으로 이동
            child: IconButton(
              icon: const Icon(Icons.clear), // X 아이콘
              onPressed: () {
                if (_diaryController.text.isEmpty) {
                  Navigator.of(context).pop(); // 작성 화면 닫기
                  widget.onClose(); // Call onClose to switch to the calendar tab
                } else {
                  _showCancelConfirmationDialog(); // 확인 다이얼로그 표시
                }
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.only(left: 6.0), // 왼쪽에 6만큼 여백 추가
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
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
                    final preview = diary['content']!.length > 20
                        ? '${diary['content']!.substring(0, 20)}...'
                        : diary['content']!;
                    return Dismissible(
                      key: Key('${diary['content']}$index'),
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
                        onTap: () => _viewDiaryDetail(diary['content']!, diary['time']!, index),
                        child: Container(
                          width: double.infinity, // 가로 길이를 부모 위젯에 맞게 설정
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(16.0),
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
                              Text(
                                '작성 시간: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(diary['time']!))}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10.0),
              if (_existingDiaries.length < 3) // 일기 개수가 3개 미만일 때만 버튼 보이기
                Center(
                  child: ElevatedButton(
                    onPressed: _navigateToDiaryCreation,
                    child: const Text('일기 작성'),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 20.0), // 날짜와 '당신의 이야기를 기록해보세요' 사이 간격 추가
              const Center(
                child: Text(
                  '당신의 이야기를 기록해보세요',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 50.0), // '당신의 이야기를 기록해보세요'와 글 작성 칸 사이 간격 추가
              Expanded(
                child: TextField(
                  controller: _diaryController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '무엇이든 자유롭게 적어보세요',
                  ),
                  expands: false,
                  minLines: 8, // 최소 줄 수
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _existingDiaries.isEmpty
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            _saveDiary(_diaryController.text);
          },
          child: const Text('작성 완료'),
        ),
      )
          : null,
    );
  }
}

class DiaryCreationScreen extends StatelessWidget {
  final String? initialContent;
  final bool isEditMode;
  final void Function(String) onSave;

  const DiaryCreationScreen({
    super.key,
    this.initialContent,
    this.isEditMode = false,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller =
    TextEditingController(text: initialContent);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '일기 수정' : '일기 작성'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              onSave(controller.text);
              Navigator.of(context).pop(); // Go back after saving
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '일기 내용을 입력하세요',
          ),
        ),
      ),
    );
  }
}

class DiaryDetailScreen extends StatelessWidget {
  final DateTime date;
  final String content;
  final String time;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiaryDetailScreen({
    super.key,
    required this.date,
    required this.content,
    required this.time,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            Text(
              '작성 시간: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(time))}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 사용자 의도치 않은 닫기 방지
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text(
            '정말로 이 일기를 삭제하시겠습니까?',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 버튼들 중앙 정렬
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                    },
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      onDelete(); // 일기 삭제
                    },
                    child: const Text('삭제'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
