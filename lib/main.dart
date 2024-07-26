import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 로케일 데이터를 불러오기 위한 패키지
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/diary_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // 로케일 데이터 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MyHomePage(title: '달력'),
        //'/my_page': (context) => const MyPage(), // MY 페이지로 이동
      },
      locale: const Locale('ko', 'KR'), // 로케일을 한국어로 설정
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime? _selectedDay; // 초기값을 null로 설정
  DateTime _focusedDay = DateTime.now();
  int _selectedIndex = 0;

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    // 현재 날짜와 선택한 날짜를 비교
    if (selectedDay.isAfter(DateTime.now())) {
      // 미래의 날짜를 선택한 경우
      _showFutureDateSnackbar();
    } else {
      // 과거 또는 현재 날짜를 선택한 경우
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DiaryScreen(
            selectedDay: selectedDay,
            onClose: () {
              setState(() {
                _selectedIndex = 0; // 캘린더 탭으로 이동
              });
            },
          ),
        ),
      ).then((_) {
        // 네비게이션이 pop된 후 실행될 코드
        setState(() {
          _selectedIndex = 0; // 캘린더 탭으로 이동
        });
      });
    }
  }

  void _showFutureDateSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '미래 일기는 작성할 수 없어요!',
          style: TextStyle(fontSize: 18.0), // 내용 텍스트 사이즈 조정
        ),
        duration: const Duration(seconds: 2), // 메시지가 표시되는 시간
        behavior: SnackBarBehavior.floating, // 스낵바를 화면 중앙에 띄우기
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // 모서리 둥글게
        ),
        margin: const EdgeInsets.all(16.0), // 스낵바의 여백
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final now = DateTime.now();

    if (index == 0) {
      Navigator.pushNamed(context, '/home'); // 캘린더 페이지로 이동
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryScreen(
            selectedDay: now,
            onClose: () {
              setState(() {
                _selectedIndex = 0; // 캘린더 탭으로 이동
              });
            },
          ),
        ),
      ).then((_) {
        // 네비게이션이 pop된 후 실행될 코드
        setState(() {
          _selectedIndex = 0; // 캘린더 탭으로 이동
        });
      });
    } else if (index == 2) {
      Navigator.pushNamed(context, '/my_page'); // MY 페이지로 이동
    }
  }

  void _onLeftArrowPressed() {
    setState(() {
      _focusedDay = DateTime(
        _focusedDay.year,
        _focusedDay.month - 1,
      );
    });
  }

  void _onRightArrowPressed() {
    setState(() {
      _focusedDay = DateTime(
        _focusedDay.year,
        _focusedDay.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // AppBar 배경 색상 변경
        elevation: 0, // 그림자 제거
        title: null, // 제목을 표시하지 않음
        toolbarHeight: 35.0, // AppBar 높이 조정
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2.0), // 왼쪽에 약간의 여백 추가
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _onLeftArrowPressed,
                ),
                Text(
                  DateFormat.yMMMM('ko_KR').format(_focusedDay), // 한국어로 월 표시
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _onRightArrowPressed,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.0), // 간격 추가
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    locale: 'ko_KR', // 달력 로케일을 한국어로 설정
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    calendarFormat: CalendarFormat.month,
                    rowHeight: 80.0, // 각 행의 높이를 조정합니다 (요일과 날짜 사이의 간격)
                    headerVisible: false, // 기본 헤더 숨김
                    daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(fontSize: 13.0), // 요일 글자 크기 조정
                        weekendStyle: TextStyle(fontSize: 13.0), // 주말 글자 크기 조정
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border(
                              bottom: BorderSide(color: Colors.transparent, width: 16), // 요일과 날짜 사이 공백 (여기서 조정)
                            )
                        )
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, focusedDay) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage('assets/circle.png'), // 이미지 경로
                                    radius: 20.0, // 이미지의 반지름
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4.0, // 날짜를 셀의 상단에 배치
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      selectedBuilder: (context, date, focusedDay) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: Colors.deepPurple,
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage('assets/sample_image.png'), // 이미지 경로
                                    radius: 20.0, // 이미지의 반지름
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4.0, // 날짜를 셀의 상단에 배치
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      todayBuilder: (context, date, focusedDay) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: Colors.blueAccent,
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage('assets/sample_image.png'), // 이미지 경로
                                    radius: 20.0, // 이미지의 반지름
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4.0, // 날짜를 셀의 상단에 배치
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      outsideBuilder: (context, date, focusedDay) {
                        return SizedBox.shrink(); // 현재 달에 속하지 않는 날짜를 숨김
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      cellMargin: const EdgeInsets.all(4.0), // 셀 사이의 간격을 조절합니다
                      cellPadding: const EdgeInsets.all(8.0), // 셀 내부의 간격을 조절합니다
                      todayDecoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.lightBlueAccent, // 오늘 날짜 강조
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0), // 요일과 달력 사이 간격 추가
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      color: Colors.black, // 검정색 직선
                      height: 1.0, // 선 두께
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: '오늘일기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'MY',
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime? day1, DateTime? day2) {
    if (day1 == null || day2 == null) {
      return false;
    }
    return day1.year == day2.year && day1.month == day2.month && day1.day == day2.day;
  }
}
