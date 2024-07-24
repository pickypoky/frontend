import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 로케일 데이터를 불러오기 위한 패키지
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/diary_screen.dart';
import 'screens/diary_final.dart';
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
  var _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final prefs = await SharedPreferences.getInstance();
    final diaryKey = DateFormat('yyyy-MM-dd').format(selectedDay);
    final diaryContent = prefs.getString(diaryKey);
    final selectedEmoji = prefs.getString('${diaryKey}_emoji') ?? '';

    if (diaryContent != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DiaryDetailScreen(
            selectedDay: selectedDay,
            diaryContent: diaryContent,
            emoji: selectedEmoji,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DiaryScreen(selectedDay: selectedDay),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // AppBar 배경 색상 변경
        elevation: 0, // 그림자 제거
        title: null, // 제목을 표시하지 않음
        toolbarHeight: 48.0, // AppBar 높이 조정
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR', // 달력 로케일을 한국어로 설정
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            rowHeight: 85.0, // 각 행의 높이를 조정합니다
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: const Icon(Icons.chevron_left),
              rightChevronIcon: const Icon(Icons.chevron_right),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(4.0), // 셀 사이의 간격을 조절합니다
              cellPadding: const EdgeInsets.all(8.0), // 셀 내부의 간격을 조절합니다
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Selected day: ${_selectedDay.toLocal()}',
              style: Theme.of(context).textTheme.headline6,
            ),
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
