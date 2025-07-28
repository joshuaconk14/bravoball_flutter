import 'package:flutter/foundation.dart';

/// Service to manage loading states with progress tracking
class LoadingStateService extends ChangeNotifier {
  static LoadingStateService? _instance;
  static LoadingStateService get instance => _instance ??= LoadingStateService._();
  
  LoadingStateService._();

  bool _isLoading = false;
  double _progress = 0.0;
  String _currentMessage = '';
  List<String> _loadingSteps = [];
  int _currentStep = 0;
  LoadingType _loadingType = LoadingType.authentication;

  // Getters
  bool get isLoading => _isLoading;
  double get progress => _progress;
  String get currentMessage => _currentMessage;
  List<String> get loadingSteps => _loadingSteps;
  int get currentStep => _currentStep;
  LoadingType get loadingType => _loadingType;
  bool get hasSteps => _loadingSteps.isNotEmpty;

  /// Start loading with optional steps and type
  void startLoading({
    required LoadingType type,
    List<String>? steps,
    String? initialMessage,
  }) {
    _loadingType = type;
    _loadingSteps = steps ?? _getDefaultStepsForType(type);
    _currentStep = 0;
    _progress = 0.0;
    _currentMessage = initialMessage ?? _getDefaultMessageForType(type);
    _isLoading = true;
    
    if (kDebugMode) {
      print('🔄 LoadingStateService: Started loading - Type: $type, Steps: ${_loadingSteps.length}');
    }
    
    notifyListeners();
  }

  /// Update progress (0.0 to 1.0)
  void updateProgress(double progress, {String? message}) {
    _progress = progress.clamp(0.0, 1.0);
    if (message != null) {
      _currentMessage = message;
    }
    
    // Auto-update step based on progress if we have steps
    if (_loadingSteps.isNotEmpty) {
      final newStep = (progress * _loadingSteps.length).floor();
      if (newStep != _currentStep && newStep < _loadingSteps.length) {
        _currentStep = newStep;
        if (kDebugMode) {
          print('📈 LoadingStateService: Progress ${(progress * 100).round()}% - Step $_currentStep: ${_loadingSteps[_currentStep]}');
        }
      }
    }
    
    notifyListeners();
  }

  /// Advance to next step
  void nextStep({String? customMessage}) {
    if (_currentStep < _loadingSteps.length - 1) {
      _currentStep++;
      _progress = (_currentStep + 1) / _loadingSteps.length;
      
      if (customMessage != null) {
        _currentMessage = customMessage;
      }
      
      if (kDebugMode) {
        print('➡️ LoadingStateService: Advanced to step $_currentStep: ${_loadingSteps[_currentStep]}');
      }
      
      notifyListeners();
    }
  }

  /// Complete loading
  void completeLoading() {
    _isLoading = false;
    _progress = 1.0;
    _currentStep = _loadingSteps.length - 1;
    
    if (kDebugMode) {
      print('✅ LoadingStateService: Loading completed');
    }
    
    notifyListeners();
  }

  /// Reset loading state
  void reset() {
    _isLoading = false;
    _progress = 0.0;
    _currentMessage = '';
    _loadingSteps = [];
    _currentStep = 0;
    _loadingType = LoadingType.authentication;
    notifyListeners();
  }

  /// Update message without changing progress
  void updateMessage(String message) {
    _currentMessage = message;
    notifyListeners();
  }

  /// Get default steps for each loading type
  List<String> _getDefaultStepsForType(LoadingType type) {
    switch (type) {
      case LoadingType.authentication:
        return [
          'Verifying your credentials...',
          'Setting up your session...',
          'Almost ready...',
        ];
      case LoadingType.userDataLoad:
        return [
          'Tailoring your training experience...',
          'Gathering your favorite drills...',
          'Reviewing your progress...',
          'Personalizing your settings...',
          'Everything is ready!',
        ];
      case LoadingType.login:
        return [
          'Signing you in...',
          'Preparing your dashboard...',
          'Welcome back!',
        ];
      case LoadingType.registration:
        return [
          'Creating your training profile...',
          'Setting up your preferences...',
          'Preparing your first session...',
          'Welcome to BravoBall!',
        ];
      case LoadingType.drillLoad:
        return [
          'Curating your drill library...',
          'Optimizing video content...',
          'Preparing your session...',
        ];
      case LoadingType.custom:
        return ['Setting everything up...'];
    }
  }

  /// Get default message for each loading type
  String _getDefaultMessageForType(LoadingType type) {
    switch (type) {
      case LoadingType.authentication:
        return 'Checking authentication...';
      case LoadingType.userDataLoad:
        return 'Setting up your training...';
      case LoadingType.login:
        return 'Signing you in...';
      case LoadingType.registration:
        return 'Creating your account...';
      case LoadingType.drillLoad:
        return 'Loading training content...';
      case LoadingType.custom:
        return 'Loading...';
    }
  }
}

/// Types of loading operations
enum LoadingType {
  authentication,
  userDataLoad,
  login,
  registration,
  drillLoad,
  custom,
}