import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Notification Service for Timer Alerts and Lock Screen Widget
/// Provides persistent timer notifications with live countdown and controls
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get shared => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Timer notification state
  static const int _timerNotificationId = 1000;
  bool _isTimerNotificationActive = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // ✅ IMPROVED: Better Android notification channel setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initializationSettings);
    
    // ✅ ADDED: Create Android notification channels explicitly
    await _createAndroidNotificationChannels();
    
    _isInitialized = true;

    if (kDebugMode) {
      print('🔔 Notification service initialized with Android channels');
    }
  }

  /// ✅ NEW: Create Android notification channels for better compatibility
  Future<void> _createAndroidNotificationChannels() async {
    if (kDebugMode) {
      print('📱 Creating Android notification channels...');
    }

    // Timer Widget Channel - for persistent timer notifications
    const timerWidgetChannel = AndroidNotificationChannel(
      'timer_widget_channel',
      'Drill Timer Widget',
      description: 'Live drill timer with controls',
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
      enableLights: false,
      showBadge: true,
    );

    // Timer Completion Channel - for completion alerts
    const timerCompletionChannel = AndroidNotificationChannel(
      'timer_completion_channel',
      'Timer Completion',
      description: 'Drill timer completion alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    // Legacy Timer Channel - for scheduled notifications
    const timerChannel = AndroidNotificationChannel(
      'timer_channel',
      'Drill Timer',
      description: 'Notifications for drill timer completion',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    // Create all channels
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(timerWidgetChannel);
        
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(timerCompletionChannel);
        
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(timerChannel);

    if (kDebugMode) {
      print('✅ Android notification channels created successfully');
    }
  }

  /// Start persistent timer notification (lock screen widget)
  Future<void> startTimerNotification({
    required String drillName,
    required int totalDurationSeconds,
    required int remainingSeconds,
    bool isPaused = false,
  }) async {
    if (!_isInitialized) await initialize();

    final progress = ((totalDurationSeconds - remainingSeconds) / totalDurationSeconds * 100).round();
    final timeRemaining = _formatTime(remainingSeconds);
    
    // Create actions list separately to avoid const issues
    final actions = [
      AndroidNotificationAction(
        'pause_resume',
        isPaused ? 'Resume' : 'Pause',
      ),
      AndroidNotificationAction(
        'stop_timer',
        'Stop',
      ),
    ];
    
    final androidDetails = AndroidNotificationDetails(
      'timer_widget_channel',
      'Drill Timer Widget',
      channelDescription: 'Live drill timer with controls',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Makes it persistent
      autoCancel: false, // Can't be swiped away
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      playSound: false, // No sound for updates
      enableVibration: false, // No vibration for updates
      actions: actions,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false, // Don't show as popup
      presentBadge: false,
      presentSound: false,
      threadIdentifier: 'drill_timer_thread',
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // This is the text that shows on the lock screen widget
    final statusText = isPaused ? 'PAUSED' : 'ACTIVE';
    final title = '⏱️ $drillName - $statusText';
    final body = '$timeRemaining remaining • ${progress}% complete';

    // This is the notification that shows on the lock screen
    await _notifications.show(
      _timerNotificationId,
      title,
      body,
      platformDetails,
    );

    _isTimerNotificationActive = true;

    if (kDebugMode) {
      print('🔔 Timer notification updated: $timeRemaining ($progress%)');
    }
  }

  /// Update timer notification with new time
  Future<void> updateTimerNotification({
    required String drillName,
    required int totalDurationSeconds,
    required int remainingSeconds,
    bool isPaused = false,
  }) async {
    if (!_isTimerNotificationActive) return;
    
    await startTimerNotification(
      drillName: drillName,
      totalDurationSeconds: totalDurationSeconds,
      remainingSeconds: remainingSeconds,
      isPaused: isPaused,
    );
  }

  /// Stop and remove timer notification
  Future<void> stopTimerNotification() async {
    if (!_isTimerNotificationActive) return;
    
    await _notifications.cancel(_timerNotificationId);
    _isTimerNotificationActive = false;
    
    if (kDebugMode) {
      print('🔕 Timer notification stopped');
    }
  }

  /// Show timer completion notification
  Future<void> showTimerCompletionNotification({
    required String drillName,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'timer_completion_channel',
      'Timer Completion',
      channelDescription: 'Drill timer completion alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Set complete notification
    await _notifications.show(
      _timerNotificationId + 1,
      '🎯 Set Complete!',
      '$drillName timer finished. Great work!',
      platformDetails,
    );

    if (kDebugMode) {
      print('🔔 Timer completion notification shown');
    }
  }

  /// Schedule timer completion notification (legacy method)
  Future<void> scheduleTimerNotification({
    required int durationSeconds,
    required String drillName,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Drill Timer',
      channelDescription: 'Notifications for drill timer completion',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert to TZDateTime for scheduled notifications
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: durationSeconds));

    await _notifications.zonedSchedule(
      0, // notification id
      'Timer Complete! 🎯',
      'Your $drillName set is finished. Time for the next set!',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    if (kDebugMode) {
      print('🔔 Scheduled timer notification for ${durationSeconds}s');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _isTimerNotificationActive = false;
    
    if (kDebugMode) {
      print('🔕 All notifications cancelled');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Check if timer notification is currently active
  bool get isTimerNotificationActive => _isTimerNotificationActive;

  /// Format seconds to MM:SS
  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 