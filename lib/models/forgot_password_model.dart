import 'package:flutter/foundation.dart';

class ForgotPasswordModel extends ChangeNotifier {
  bool _showForgotPasswordPage = false;
  String _forgotPasswordMessage = '';
  int _forgotPasswordStep = 1; // 1: email, 2: code, 3: new password
  String _forgotPasswordEmail = '';
  String _forgotPasswordCode = '';
  String _forgotPasswordNewPassword = '';
  String _forgotPasswordConfirmPassword = '';
  bool _isNewPasswordVisible = false;

  // Getters
  bool get showForgotPasswordPage => _showForgotPasswordPage;
  String get forgotPasswordMessage => _forgotPasswordMessage;
  int get forgotPasswordStep => _forgotPasswordStep;
  String get forgotPasswordEmail => _forgotPasswordEmail;
  String get forgotPasswordCode => _forgotPasswordCode;
  String get forgotPasswordNewPassword => _forgotPasswordNewPassword;
  String get forgotPasswordConfirmPassword => _forgotPasswordConfirmPassword;
  bool get isNewPasswordVisible => _isNewPasswordVisible;

  // Setters
  set showForgotPasswordPage(bool value) {
    _showForgotPasswordPage = value;
    notifyListeners();
  }

  set forgotPasswordMessage(String value) {
    _forgotPasswordMessage = value;
    notifyListeners();
  }

  set forgotPasswordStep(int value) {
    _forgotPasswordStep = value;
    // Clear password fields when moving to step 3
    if (value == 3) {
      _forgotPasswordNewPassword = '';
      _forgotPasswordConfirmPassword = '';
    }
    notifyListeners();
  }

  set forgotPasswordEmail(String value) {
    _forgotPasswordEmail = value;
    notifyListeners();
  }

  set forgotPasswordCode(String value) {
    _forgotPasswordCode = value;
    notifyListeners();
  }

  set forgotPasswordNewPassword(String value) {
    _forgotPasswordNewPassword = value;
    notifyListeners();
  }

  set forgotPasswordConfirmPassword(String value) {
    _forgotPasswordConfirmPassword = value;
    notifyListeners();
  }

  set isNewPasswordVisible(bool value) {
    _isNewPasswordVisible = value;
    notifyListeners();
  }

  void resetForgotPasswordState() {
    _forgotPasswordStep = 1;
    _forgotPasswordEmail = '';
    _forgotPasswordCode = '';
    _forgotPasswordNewPassword = '';
    _forgotPasswordConfirmPassword = '';
    _forgotPasswordMessage = '';
    _showForgotPasswordPage = false;
    notifyListeners();
  }
} 