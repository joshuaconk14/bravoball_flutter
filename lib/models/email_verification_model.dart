import 'package:flutter/material.dart';

/// Email Verification Model
/// Manages state for the email verification flow when updating user email
class EmailVerificationModel extends ChangeNotifier {
  // Email verification step (1: enter new email, 2: verify code)
  int _emailVerificationStep = 1;
  
  // Current user email
  String _currentEmail = '';
  
  // New email address to update to
  String _newEmail = '';
  
  // Verification code
  String _emailVerificationCode = '';
  
  // Message for feedback
  String _emailVerificationMessage = '';

  // Getters
  int get emailVerificationStep => _emailVerificationStep;
  String get currentEmail => _currentEmail;
  String get newEmail => _newEmail;
  String get emailVerificationCode => _emailVerificationCode;
  String get emailVerificationMessage => _emailVerificationMessage;

  // Setters
  set emailVerificationStep(int step) {
    _emailVerificationStep = step;
    notifyListeners();
  }

  set currentEmail(String email) {
    _currentEmail = email;
    notifyListeners();
  }

  set newEmail(String email) {
    _newEmail = email;
    notifyListeners();
  }

  set emailVerificationCode(String code) {
    _emailVerificationCode = code;
    notifyListeners();
  }

  set emailVerificationMessage(String message) {
    _emailVerificationMessage = message;
    notifyListeners();
  }

  /// Reset the email verification state
  void resetEmailVerificationState() {
    _newEmail = '';
    _emailVerificationCode = '';
    _emailVerificationMessage = '';
    notifyListeners();
  }

  /// Dispose of the model
  @override
  void dispose() {
    super.dispose();
  }
} 