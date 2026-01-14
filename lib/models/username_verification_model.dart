import 'package:flutter/material.dart';

class UsernameVerificationModel extends ChangeNotifier {
  String currentUsername = '';
  String newUsername = '';
  String usernameVerificationMessage = '';
  bool isLoading = false;

  void setMessage(String message) {
    usernameVerificationMessage = message;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }
}
