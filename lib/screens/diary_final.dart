import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiaryDetailScreen extends StatelessWidget {
  final DateTime selectedDay;
  final String diaryContent;

  const DiaryDetailScreen({
    super.key,
    required this.selectedDay,
    required this.diaryContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diary Details for ${DateFormat('yyyy-MM-dd').format(selectedDay)}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diaryContent,
              style: const TextStyle(fontSize: 18.0),
            ),
          ],
        ),
      ),
    );
  }
}
