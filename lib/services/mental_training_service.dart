import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/api_response_models.dart';
import '../models/mental_training_models.dart';

class MentalTrainingService extends ChangeNotifier {
  static final MentalTrainingService _instance = MentalTrainingService._internal();
  factory MentalTrainingService() => _instance;
  MentalTrainingService._internal();

  static MentalTrainingService get shared => _instance;

  final ApiService _apiService = ApiService.shared;

  List<MentalTrainingQuote> _quotes = [];
  bool _isLoadingQuotes = false;
  String? _lastError;

  // Getters
  List<MentalTrainingQuote> get quotes => _quotes;
  bool get isLoadingQuotes => _isLoadingQuotes;
  String? get lastError => _lastError;

  /// Fetch mental training quotes from the backend
  Future<List<MentalTrainingQuote>> fetchQuotes({
    int limit = 50,
    String? quoteType,
  }) async {
    _isLoadingQuotes = true;
    _lastError = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🧠 Fetching mental training quotes...');
      }

      final Map<String, String> queryParams = {
        'limit': limit.toString(),
      };

      if (quoteType != null) {
        queryParams['quote_type'] = quoteType;
      }

      final response = await _apiService.request(
        endpoint: '/api/mental-training/quotes',
        method: 'GET',
        queryParameters: queryParams,
        requiresAuth: false, // ✅ UPDATED: Changed to false for guest mode access
      );

      if (response.isSuccess && response.data != null) {
        // Handle wrapped response format - quotes might be in 'data' field or directly as array
        List<dynamic> quotesData;
        if (response.data is List) {
          quotesData = response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          quotesData = (data['data'] ?? data['quotes'] ?? []) as List<dynamic>;
        } else {
          quotesData = [];
        }
        
        _quotes = quotesData.map((json) => MentalTrainingQuote.fromJson(json)).toList();
        
        if (kDebugMode) {
          print('✅ Successfully fetched ${_quotes.length} mental training quotes');
        }
        
        return _quotes;
      } else {
        throw Exception(response.error ?? 'Failed to fetch quotes');
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('❌ Error fetching mental training quotes: $e');
      }
      return [];
    } finally {
      _isLoadingQuotes = false;
      notifyListeners();
    }
  }
} 