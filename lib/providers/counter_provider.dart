import 'package:flutter/material.dart';

class CounterProvider extends ChangeNotifier {
  int _count = 0;
  double _value = 0.0;
  int get count => _count;
  double get value => _value;

  void increment() {
    _count++;
    
    notifyListeners();
  }
  void updateSlider(double newValue) {
    _value = newValue;
    _count = newValue.round();
    notifyListeners();
  } 
}