import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/diary_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0x878AFF)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MyHomePage(title: '달력'),
      },
      locale: const Locale('ko', 'KR'),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 5), () {});
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash.png', fit: BoxFit.cover,
            ), // 스플래시 이미지 설정
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
            )
          ],
        ),
      ),
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
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  int _selectedIndex = 0;
  Map<String, String> _diaryData = {};
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('accessToken');
    });
    _fetchDiaries();
  }

  Future<void> _fetchDiaries() async {
    if (_token == null) {
      print('Token is null');
      return;
    }

    final url = Uri.parse('https://pickypoky.com/api/diary?diaryDate=${DateFormat('yyyy-MM-dd').format(_focusedDay)}');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final calendarData = responseBody['result']['calender'] as Map<String, dynamic>;

      setState(() {
        _diaryData = Map<String, String>.from(calendarData);
      });
    } else {
      print('Failed to fetch diaries: ${response.body}');
    }
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (selectedDay.isAfter(DateTime.now())) {
      _showFutureDateSnackbar();
    } else {
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
                _selectedIndex = 0;
              });
            },
          ),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  void _showFutureDateSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '미래 일기는 작성할 수 없어요!',
          style: TextStyle(fontSize: 18.0),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final now = DateTime.now();

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryScreen(
            selectedDay: now,
            onClose: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 2) {
      Navigator.pushNamed(context, '/my_page');
    }
  }

  void _onLeftArrowPressed() {
    setState(() {
      _focusedDay = DateTime(
        _focusedDay.year,
        _focusedDay.month - 1,
      );
      _fetchDiaries();
    });
  }

  void _onRightArrowPressed() {
    setState(() {
      _focusedDay = DateTime(
        _focusedDay.year,
        _focusedDay.month + 1,
      );
      _fetchDiaries();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: null,
        toolbarHeight: 35.0,
        iconTheme: IconThemeData(color: Colors.blue),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _onLeftArrowPressed,
                ),
                Text(
                  DateFormat.yMMMM('ko_KR').format(_focusedDay),
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
          SizedBox(height: 8.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    calendarFormat: CalendarFormat.month,
                    rowHeight: 80.0,
                    headerVisible: false,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontSize: 13.0),
                      weekendStyle: TextStyle(fontSize: 13.0),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: Colors.transparent, width: 16),
                        ),
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, focusedDay) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(date);
                        final diaryStatus = _diaryData[dateKey] ?? 'empty';

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
                                    backgroundImage: AssetImage(
                                      diaryStatus == 'empty'
                                          ? 'assets/basic_round.png'
                                          : 'assets/sample_image.png',
                                    ),
                                    radius: 20.0,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4.0,
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
                        final dateKey = DateFormat('yyyy-MM-dd').format(date);
                        final diaryStatus = _diaryData[dateKey] ?? 'empty';

                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: Colors.transparent,
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage(
                                      diaryStatus == 'empty'
                                          ? 'assets/touched.png'  // 선택된 날짜에 대한 이미지 변경
                                          : 'assets/sample_image.png',
                                    ),
                                    radius: 20.0,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4.0,
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
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage('assets/basic_round.png'),
                                    radius: 20.0,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4.0,
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
                      outsideBuilder: (context, date, focusedDay) {
                        return SizedBox.shrink();
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      cellMargin: const EdgeInsets.all(4.0),
                      cellPadding: const EdgeInsets.all(8.0),
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
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
            label: ' ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: ' ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: ' ',
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