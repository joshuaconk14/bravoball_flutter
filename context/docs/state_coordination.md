# State Coordination Patterns

## State Machine Pattern
**Problem**: Unpredictable state transitions and race conditions  
**Solution**: Explicit state definitions with controlled transitions

```dart
enum SessionState { idle, inProgress, canComplete, completing, completed }

class SessionManager extends ChangeNotifier {
  SessionState _state = SessionState.idle;
  
  void startSession() {
    if (_state != SessionState.idle) {
      throw StateError('Can only start session from idle state');
    }
    _setState(SessionState.inProgress);
  }
  
  void _setState(SessionState newState) {
    if (kDebugMode) print('State: $_state → $newState');
    _state = newState;
    notifyListeners();
  }
}
```

## Coordinator Pattern  
**Problem**: Race conditions in async operations  
**Solution**: Centralized operation coordination with guards

```dart
class SyncCoordinator {
  final Map<String, Completer<void>> _activeOperations = {};
  final Map<String, Timer> _timers = {};
  
  Future<void> executeImmediate(String key, Future<void> Function() operation) async {
    if (_activeOperations.containsKey(key)) {
      if (kDebugMode) print('⚠️ Operation $key already in progress');
      return;
    }
    
    final completer = Completer<void>();
    _activeOperations[key] = completer;
    
    try {
      await operation();
    } finally {
      _activeOperations.remove(key);
      completer.complete();
    }
  }
  
  void scheduleSync(String key, Duration delay, Future<void> Function() operation) {
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, () async {
      await executeImmediate(key, operation);
    });
  }
}
```

## Debounced Operations
**Problem**: Excessive API calls from rapid user input  
**Solution**: Batch operations with configurable delays

```dart
class DebounceController {
  Timer? _timer;
  final Duration delay;
  
  DebounceController({this.delay = const Duration(milliseconds: 300)});
  
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  void dispose() {
    _timer?.cancel();
  }
}

// Usage
final searchDebounce = DebounceController();
searchDebounce.run(() => performSearch(query));
```

## Operation Guards
**Problem**: Concurrent execution of critical operations  
**Solution**: Guard flags to prevent overlapping operations

```dart
class GuardedService {
  final Map<String, bool> _operationFlags = {};
  
  Future<T> guardedOperation<T>(String key, Future<T> Function() operation) async {
    if (_operationFlags[key] == true) {
      throw StateError('Operation $key already in progress');
    }
    
    _operationFlags[key] = true;
    try {
      return await operation();
    } finally {
      _operationFlags[key] = false;
    }
  }
}
```

## Real-World Example: AppStateService Integration
```dart
class AppStateService extends ChangeNotifier {
  // State management
  SessionState _sessionState = SessionState.idle;
  LoadingState _loadingState = LoadingState.idle;
  
  // Coordination
  final SyncCoordinator _syncCoordinator = SyncCoordinator();
  static const Duration _syncDebounce = Duration(milliseconds: 500);
  
  // State transitions
  void _setSessionState(SessionState state) {
    if (kDebugMode) print('🔄 Session: $_sessionState → $state');
    _sessionState = state;
    notifyListeners();
  }
  
  // Coordinated operations
  Future<void> updatePreferences(UserPreferences prefs) async {
    _syncCoordinator.scheduleSync('preferences', _syncDebounce, () async {
      await _savePreferences(prefs);
    });
  }
  
  Future<void> completeSession() async {
    if (_sessionState != SessionState.canComplete) return;
    
    await _syncCoordinator.executeImmediate('session_complete', () async {
      _setSessionState(SessionState.completing);
      await _performSessionCompletion();
      _setSessionState(SessionState.completed);
    });
  }
}
```

## Best Practices
- **Single State Source**: One coordinator per service
- **Clear State Names**: Use descriptive enum values
- **Transition Logging**: Debug state changes
- **Operation Keys**: Use consistent naming for operations
- **Cleanup**: Dispose timers and cancel operations
- **Error Handling**: Wrap operations in try-catch blocks 