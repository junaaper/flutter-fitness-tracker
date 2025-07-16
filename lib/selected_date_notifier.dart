// selected_date_notifier.dart
import 'package:flutter/material.dart';

class SelectedDateNotifier extends ChangeNotifier {
  DateTime _selected = DateTime.now();
  DateTime get selected => _selected;

  void setDate(DateTime dt) {
    _selected = dt;
    notifyListeners();
  }

  void resetToToday() {
    setDate(DateTime.now());
  }
}
