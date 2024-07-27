import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DiaryScreen extends StatefulWidget {
  final DateTime selectedDay;
  final VoidCallback onClose;

  const DiaryScreen({
    super.key,
    required this.selectedDay,
    required this.onClose,
  });

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _currentDay;
  final TextEditingController _diaryController = TextEditingController();
  Map<String, List<Map<String, dynamic>>> _diariesByDate = {};
  String? _token;

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('accessToken');
    });
    if (_token != null) {
      _fetchDiaries();
    }
  }

  Future<void> _fetchDiaries() async {
    final url = Uri.parse('https://pickypoky.com/api/diary/list?diaryDate=${DateFormat('yyyy-MM-dd').format(_currentDay)}');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['isSuccess']) {
        final result = responseBody['result'] as List<dynamic>;

        final Map<String, List<Map<String, dynamic>>> newDiariesByDate = {};

        for (var entry in result) {
          final date = entry['diaryDate'] as String;
          final diaries = (entry['diaries'] as List<dynamic>).map((item) {
            final diary = item as Map<String, dynamic>;
            diary['contents'] = diary['contents'] ?? ''; // null을 빈 문자열로 변환
            diary['tags'] = diary['tags'] ?? []; // null을 빈 리스트로 변환
            diary['emoji'] = diary['emoji'] ?? ''; // null을 빈 문자열로 변환
            return diary;
          }).toList();

          newDiariesByDate[date] = diaries;
        }

        setState(() {
          _diariesByDate = newDiariesByDate;
        });
      } else {
        print('서버 응답 형식이 올바르지 않습니다.');
      }
    } else {
      print('다이어리 목록 가져오기 실패: ${response.body}');
    }
  }

  Future<void> _saveDiary(String content) async {
    const int maxContentLength = 1000; // 예: 1000자로 설정

    if (content.length > maxContentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 내용이 너무 깁니다. 최대 $maxContentLength 자까지 입력 가능합니다.')),
      );
      return;
    }

    final url = Uri.parse('https://pickypoky.com/api/diary');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: json.encode({
        'diaryDate': DateFormat('yyyy-MM-dd').format(_currentDay),
        'contents': content,
      }),
    );

    final responseBody = utf8.decode(response.bodyBytes);
    final decodedResponse = json.decode(responseBody);

    if (response.statusCode == 200 && decodedResponse['isSuccess']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기가 저장되었습니다.')),
      );

      setState(() {
        _diaryController.clear();
        _fetchDiaries(); // 일기 저장 후 목록을 갱신
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DiaryCreationResultScreen(
            diary: decodedResponse['result'],
          ),
        ),
      );
    } else {
      print('일기 저장 실패: ${decodedResponse['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 저장 실패: ${decodedResponse['message']}')),
      );
    }
  }

  Future<void> _deleteDiary(String diarySeq) async {
    final url = Uri.parse('https://pickypoky.com/api/diary/$diarySeq');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일기가 삭제되었습니다.')),
        );
        _fetchDiaries(); // 일기 삭제 후 목록을 갱신
      } else {
        print('일기 삭제 실패: ${responseBody['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일기 삭제 실패: ${responseBody['message']}')),
        );
      }
    } else {
      print('일기 삭제 실패: ${response.body}');
    }
  }

  void _navigateToDiaryCreation([String? content]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiaryCreationScreen(
          initialContent: content,
          onSave: (newContent) {
            _saveDiary(newContent);
          },
        ),
      ),
    );
  }

  void _viewDiaryDetail(Map<String, dynamic> diary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          date: DateTime.parse(diary['diaryDate']),
          content: diary['contents'] ?? '', // null 체크 추가
          time: diary['createdAt'],
          tags: List<String>.from(diary['tags'] ?? []),
          emoji: diary['emoji'] ?? '',
          onEdit: () {
            Navigator.of(context).pop();
            _navigateToDiaryCreation(diary['contents']);
          },
          onDelete: () {
            _deleteDiary(diary['diarySeq']);
          },
        ),
      ),
    );
  }

  void _changeDate(int offset) {
    setState(() {
      _currentDay = _currentDay.add(Duration(days: offset));
      _fetchDiaries(); // 날짜 변경 시 일기 목록을 갱신
    });
  }

  @override
  Widget build(BuildContext context) {
    final diariesForSelectedDate = _diariesByDate[DateFormat('yyyy-MM-dd').format(_currentDay)] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (diariesForSelectedDate.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: diariesForSelectedDate.length,
                  itemBuilder: (context, index) {
                    final diary = diariesForSelectedDate[index];
                    final content = diary['contents'] ?? ''; // null 체크 추가
                    final preview = content.length > 20 ? '${content.substring(0, 20)}...' : content;

                    return Dismissible(
                      key: Key('${diary['diarySeq']}$index'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteDiary(diary['diarySeq']);
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
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(preview),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            Expanded(
              child: TextField(
                controller: _diaryController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '무엇이든 자유롭게 적어보세요',
                ),
                minLines: 8,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _saveDiary(_diaryController.text);
              },
              child: const Text('작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

class DiaryCreationScreen extends StatelessWidget {
  final String? initialContent;
  final void Function(String) onSave;

  const DiaryCreationScreen({
    super.key,
    this.initialContent,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: initialContent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 작성'),
        automaticallyImplyLeading: false, // 왼쪽 상단 뒤로가기 버튼 삭제
        actions: [
          IconButton(
            icon: const Icon(Icons.close), // X 버튼 추가
            onPressed: () {
              Navigator.of(context).pop(); // 뒤로가기
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20.0), // 날짜와 제목 사이 간격 추가
            const Center(
              child: Text(
                '당신의 이야기를 기록해보세요',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50.0), // 제목과 글 작성 칸 사이 간격 추가
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '무엇이든 자유롭게 적어보세요',
                ),
                minLines: 8, // 최소 줄 수
              ),
            ),
            const SizedBox(height: 16.0), // 작성 완료 버튼과 입력 칸 사이 간격 추가
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: () {
                  onSave(controller.text);
                  Navigator.of(context).pop(); // 뒤로가기
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
  final DateTime date;
  final String content;
  final String time;
  final List<String> tags;
  final String emoji;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiaryDetailScreen({
    super.key,
    required this.date,
    required this.content,
    required this.time,
    required this.tags,
    required this.emoji,
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
            const SizedBox(height: 16.0),
            Text(
              '태그: ${tags.join(', ')}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
            Text(
              '이모지: $emoji',
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
                      Navigator.of(context).pop(); // Return to the previous screen
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

class DiaryCreationResultScreen extends StatelessWidget {
  final Map<String, dynamic> diary;

  const DiaryCreationResultScreen({Key? key, required this.diary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String content = diary['contents'] ?? '';
    final String date = diary['diaryDate'] ?? '';
    final String emoji = diary['emoji_origin'] ?? ''; // 서버 응답에서 emoji_origin을 가져옴
    final String tags = (diary['tags'] as List<dynamic>).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Created'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16.0),
            Text(
              '날짜 : $date',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Emoji: $emoji',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Tags: $tags',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: SingleChildScrollView(
                child: Text(content),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
