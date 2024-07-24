import 'package:flutter/material.dart';

class EmojiProvider with ChangeNotifier {
  Map<DateTime, String> _selectedEmojis = {};

  String? getEmojiForDate(DateTime date) {
    return _selectedEmojis[DateTime(date.year, date.month, date.day)];
  }

  void setEmojiForDate(DateTime date, String emoji) {
    _selectedEmojis[DateTime(date.year, date.month, date.day)] = emoji;
    notifyListeners();
  }
}
