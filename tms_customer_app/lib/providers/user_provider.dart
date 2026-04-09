import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  int? customerId;

  void setCustomerId(int id) {
    customerId = id;
    notifyListeners();
  }
}
