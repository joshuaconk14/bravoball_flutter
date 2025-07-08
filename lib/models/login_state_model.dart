import 'package:flutter/foundation.dart';

/// Login State Model
/// Mirrors Swift LoginModel for managing login form state
class LoginStateModel extends ChangeNotifier {
  String _email = '';
  String _password = '';
  String _errorMessage = '';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Getters
  String get email => _email;
  String get password => _password;
  String get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;

  // Validation
  bool get isFormValid => _email.isNotEmpty && _password.isNotEmpty;
  bool get isEmailValid => _email.contains('@') && _email.contains('.');

  // Setters
  void setEmail(String email) {
    _email = email.trim();
    _clearError();
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    _clearError();
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }

  /// Reset login info and error message (mirrors Swift resetLoginInfo)
  void resetLoginInfo() {
    _email = '';
    _password = '';
    _errorMessage = '';
    _isPasswordVisible = false;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear only the error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
} 