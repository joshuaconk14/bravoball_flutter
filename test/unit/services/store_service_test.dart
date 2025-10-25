import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bravoball_flutter/services/store_service.dart';
import 'package:bravoball_flutter/services/api_service.dart';

// Generate mocks for dependencies
@GenerateMocks([ApiService])
import 'store_service_test.mocks.dart';

void main() {
  group('StoreService', () {
    late StoreService storeService;
    late MockApiService mockApiService;

    setUp(() {
      // Reset singleton instance for each test
      StoreService._instance = null;
      storeService = StoreService.instance;
      mockApiService = MockApiService();
      
      // Inject mock API service (you'd need to modify StoreService to accept this)
      // This is why dependency injection is important for testing
    });

    tearDown(() {
      // Clean up after each test
      StoreService._instance = null;
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(storeService.treats, equals(0));
        expect(storeService.streakFreezes, equals(0));
        expect(storeService.streakRevivers, equals(0));
        expect(storeService.activeFreezeDate, isNull);
        expect(storeService.usedFreezes, isEmpty);
        expect(storeService.usedRevivers, isEmpty);
        expect(storeService.isLoading, isFalse);
        expect(storeService.error, isNull);
      });

      test('should fetch user store items on initialization', () async {
        // Arrange
        final mockResponse = {
          'treats': 10,
          'streak_freezes': 3,
          'streak_revivers': 2,
          'active_freeze_date': '2024-01-15',
          'used_freezes': ['2024-01-10', '2024-01-12'],
          'used_revivers': ['2024-01-08']
        };
        
        when(mockApiService.get('/api/store/items'))
            .thenAnswer((_) async => ApiResponse(
              isSuccess: true,
              data: mockResponse,
              statusCode: 200,
            ));

        // Act
        await storeService.initialize();

        // Assert
        expect(storeService.treats, equals(10));
        expect(storeService.streakFreezes, equals(3));
        expect(storeService.streakRevivers, equals(2));
        expect(storeService.activeFreezeDate, isNotNull);
        expect(storeService.usedFreezes, hasLength(2));
        expect(storeService.usedRevivers, hasLength(1));
        verify(mockApiService.get('/api/store/items')).called(1);
      });

      test('should handle API errors during initialization', () async {
        // Arrange
        when(mockApiService.get('/api/store/items'))
            .thenAnswer((_) async => ApiResponse(
              isSuccess: false,
              error: 'Network error',
              statusCode: 500,
            ));

        // Act
        await storeService.initialize();

        // Assert
        expect(storeService.error, equals('Failed to load store items'));
        expect(storeService.isLoading, isFalse);
      });
    });

    group('Streak Reviver Usage', () {
      test('should successfully use streak reviver', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'message': 'Streak revived! Your 5-day streak has been restored.',
          'progress_history': {
            'current_streak': 5,
            'previous_streak': 0
          },
          'store_items': {
            'streak_revivers': 1,
            'active_streak_reviver': '2024-01-15',
            'used_revivers': ['2024-01-15']
          }
        };

        when(mockApiService.post('/api/store/use-streak-reviver'))
            .thenAnswer((_) async => ApiResponse(
              isSuccess: true,
              data: mockResponse,
              statusCode: 200,
            ));

        // Act
        final result = await storeService.useStreakReviver();

        // Assert
        expect(result, isNotNull);
        expect(result!['success'], isTrue);
        expect(storeService.streakRevivers, equals(1));
        expect(storeService.activeStreakReviver, isNotNull);
        expect(storeService.usedRevivers, hasLength(1));
        verify(mockApiService.post('/api/store/use-streak-reviver')).called(1);
      });

      test('should handle insufficient streak revivers', () async {
        // Arrange
        when(mockApiService.post('/api/store/use-streak-reviver'))
            .thenAnswer((_) async => ApiResponse(
              isSuccess: false,
              error: 'You don\'t have any streak revivers available',
              statusCode: 400,
            ));

        // Act
        final result = await storeService.useStreakReviver();

        // Assert
        expect(result, isNull);
        expect(storeService.error, contains('streak revivers'));
      });

      test('should handle no lost streak to restore', () async {
        // Arrange
        when(mockApiService.post('/api/store/use-streak-reviver'))
            .thenAnswer((_) async => ApiResponse(
              isSuccess: false,
              error: 'You don\'t have a previous streak to restore',
              statusCode: 400,
            ));

        // Act
        final result = await storeService.useStreakReviver();

        // Assert
        expect(result, isNull);
        expect(storeService.error, contains('previous streak'));
      });
    });

    group('Streak Freeze Usage', () {
      test('should successfully use streak freeze', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'message': 'Streak freeze activated for today!',
          'freeze_date': '2024-01-15',
          'store_items': {
            'streak_freezes': 2,
            'active_freeze_date': '2024-01-15',
            'used_freezes': ['2024-01-15']
          }
        };

        when(mockApiService.post('/api/store/use-streak-freeze'))
            .thenAnswer((_) async => ApiResponse(
              isSuccess: true,
              data: mockResponse,
              statusCode: 200,
            ));

        // Act
        final result = await storeService.useStreakFreeze();

        // Assert
        expect(result, isNotNull);
        expect(result!['success'], isTrue);
        expect(storeService.streakFreezes, equals(2));
        expect(storeService.activeFreezeDate, isNotNull);
        expect(storeService.usedFreezes, hasLength(1));
      });

      test('should handle insufficient streak freezes', () async {
        // Arrange
        when(mockApiService.post('/api/store/use-streak-freeze'))
            .thenAnswer((_) async => ApiResponse(
              isSuccess: false,
              error: 'You don\'t have any streak freezes available',
              statusCode: 400,
            ));

        // Act
        final result = await storeService.useStreakFreeze();

        // Assert
        expect(result, isNull);
        expect(storeService.error, contains('streak freezes'));
      });

      test('should handle no active streak for freeze', () async {
        // Arrange
        when(mockApiService.post('/api/store/use-streak-freeze'))
            .thenAnswer((_) async => ApiResponse(
              isSuccess: false,
              error: 'You need an active streak to use a streak freeze',
              statusCode: 400,
            ));

        // Act
        final result = await storeService.useStreakFreeze();

        // Assert
        expect(result, isNull);
        expect(storeService.error, contains('active streak'));
      });
    });

    group('Date Parsing', () {
      test('should parse valid ISO date strings', () {
        // This would test the date parsing logic in _fetchUserStoreItems
        // You'd need to expose this method or test it indirectly
        final testDate = '2024-01-15';
        final parsedDate = DateTime.parse(testDate);
        
        expect(parsedDate.year, equals(2024));
        expect(parsedDate.month, equals(1));
        expect(parsedDate.day, equals(15));
      });

      test('should handle invalid date strings gracefully', () {
        // Test error handling for malformed dates
        expect(() => DateTime.parse('invalid-date'), throwsFormatException);
      });
    });

    group('State Management', () {
      test('should notify listeners when state changes', () {
        // Arrange
        bool listenerCalled = false;
        storeService.addListener(() {
          listenerCalled = true;
        });

        // Act
        storeService.notifyListeners();

        // Assert
        expect(listenerCalled, isTrue);
      });

      test('should set loading state correctly', () {
        // This would test the _setLoading method
        // You'd need to expose it or test indirectly through public methods
        expect(storeService.isLoading, isFalse);
      });
    });
  });
}
