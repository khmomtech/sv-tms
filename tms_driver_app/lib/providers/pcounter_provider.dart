import 'package:flutter/material.dart';

class PcounterProvider with ChangeNotifier {
  int _count = 0;

  get count => _count;

  void increment() {
    _count++;

    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }

  void decrement() {
    _count--;
    notifyListeners();
  }
}
