import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'another_diary_screen.dart';
import 'diary_detail_screen.dart';
import 'diary_edit_screen.dart';
import 'diary_list_screen.dart';

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
  String? _token;
  List<dynamic> _diaries = []; // 추가: 일기 목록을 저장하는 리스트

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
    _loadToken().then((_) {
      _loadDiaries(); // 추가: 일기를 불러오는 함수 호출
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('accessToken');
    });
  }

  Future<void> _loadDiaries() async {
    if (_token == null) {
      print('토큰이 없습니다.');
      return;
    }

    final url = Uri.parse('https://pickypoky.com/api/diaries?date=${DateFormat('yyyy-MM-dd').format(_currentDay)}');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = utf8.decode(response.bodyBytes);
      final decodedResponse = json.decode(responseBody);

      setState(() {
        _diaries = decodedResponse['result']; // 일기 목록 갱신
      });
    } else {
      final responseBody = utf8.decode(response.bodyBytes);
      final decodedResponse = json.decode(response.body);
      print('일기 불러오기 실패: ${decodedResponse['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 불러오기 실패: ${decodedResponse['message']}')),
      );
    }
  }

  Future<void> _saveDiary(String content) async {
    const int maxContentLength = 1000; // 예: 1000자로 설정

    if (content.length > maxContentLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기는 최대 $maxContentLength 자까지 작성 가능합니다!')),
      );
      return;
    }

    if (_token == null) {
      print('토큰이 없습니다.');
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
      });

      await _loadDiaries(); // 추가: 일기 저장 후 목록을 갱신

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

  void _navigateToDiaryCreation([String? content]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiaryCreationScreen(
          initialContent: content,
          onSave: (newContent) async {
            await _saveDiary(newContent);
            await _loadDiaries(); // 추가: 일기 저장 후 목록 갱신
          },
        ),
      ),
    );
  }

  void _viewDiaryDetail(Map<String, dynamic> diary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          diary: diary,
          onEdit: () {
            Navigator.of(context).pop();
            _navigateToDiaryCreation(diary['contents']);
          },
        ),
      ),
    );
  }

  void _changeDate(int offset) {
    setState(() {
      _currentDay = _currentDay.add(Duration(days: offset));
      _loadDiaries(); // 추가: 날짜 변경 시 일기 목록 갱신
    });
  }

  Future<void> _showExitConfirmationDialog() async {
    if (_diaryController.text.isNotEmpty) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white, // 알림창 배경 색상을 흰색으로 설정
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0), // 모서리를 살짝 둥글게 설정
            ),
            titlePadding: EdgeInsets.all(0),
            contentPadding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0), // 기본 contentPadding 조정
            title: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Image.asset('assets/ic_alert.png'), // 원하는 이미지 경로로 변경
                ),
                const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: Text(
                    '정말 나가시나요?',
                    style: TextStyle(color: Colors.black,
                      fontWeight: FontWeight.bold, ), // 검정색으로 설정
                  ),
                ),
              ],
            ),
            content: const Text(
              '지금까지 작성한 모든 내용이 사라져요!',
              style: TextStyle(color: Colors.grey), // 회색으로 설정
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xF7F7F7), // 배경 색상 설정
                      onPrimary: Colors.black, // 텍스트 색상 설정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0), // 모서리를 살짝 둥글게 설정
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8), // 버튼 사이 간격 추가
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFA89AFD), // 배경 색상 설정
                      onPrimary: Colors.white, // 텍스트 색상 설정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0), // 모서리를 살짝 둥글게 설정
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('나가기'),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (shouldExit == true) {
        Navigator.of(context).pop(); // 달력 화면으로 돌아가기
      }
    } else {
      Navigator.of(context).pop(); // 달력 화면으로 돌아가기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null, // 왼쪽 화살표 제거
        title: Row(
          mainAxisSize: MainAxisSize.min, // 왼쪽으로 보내기 위해 추가
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeDate(-1),
            ),
            Text(
              DateFormat('yyyy년 M월 d일').format(_currentDay), // 날짜 형식 변경
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 30), // 간격을 위해 추가
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitConfirmationDialog,
          ),
        ],
        automaticallyImplyLeading: false, // 자동으로 leading 아이콘을 추가하지 않도록 설정
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _diaries.isNotEmpty
                  ? DiaryListView(
                diaries: _diaries,
                onDiaryTap: _viewDiaryDetail,
              )
                  : TextField(
                controller: _diaryController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '무엇이든 자유롭게 적어볼까요?',
                ),
                minLines: 8,
              ),
            ),
            const SizedBox(height: 8.0), // 일기 작성 칸을 위로 올리기 위해 간격을 조정
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pickypocky와 내 감정 보러가기 →',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,
                  color: Color(0xFFA89AFD)),
                ),
                GestureDetector(
                  onTap: () {
                    _diaries.isNotEmpty ? _navigateToDiaryCreation() : _saveDiary(_diaryController.text);
                  },
                  child: Image.asset('assets/analysis_start.png'), // 원하는 이미지 경로로 변경
                ),
              ],
            ),
            const SizedBox(height: 16.0), // 이미지 버튼과 텍스트를 위로 올리기 위해 간격을 조정
          ],
        ),
      ),
    );
  }
}
