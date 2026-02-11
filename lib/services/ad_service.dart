import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ad_config.dart'; // ✅ ADDED: Import AdConfig
import '../utils/premium_utils.dart'; // ✅ ADDED: Import PremiumUtils
import '../utils/store_business_rules.dart'; // ✅ ADDED: Import StoreBusinessRules for reward amounts

class AdService {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;
  
  AdService._internal();
  
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isShowingAd = false;
  
  // Ad frequency settings from config
  static const int _adsAfterEveryNOpens = AdConfig.adsAfterEveryNOpens;
  static const int _minTimeBetweenAds = AdConfig.minTimeBetweenAds;
  
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🚀 Initializing AdService...');
    }
    
    // Check if ads are enabled
    if (!AdConfig.adsEnabled) {
      if (kDebugMode) {
        print('⚠️ Ads are disabled in configuration');
      }
      return;
    }
    
    try {
      // Initialize Google Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      if (kDebugMode) {
        print('✅ Google Mobile Ads SDK initialized');
      }
      
      // Load the first interstitial ad
      await _loadInterstitialAd();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing AdService: $e');
      }
    }
  }
  
  String get _adUnitId {

    
    if (kDebugMode) {
      // Use test ad unit IDs in debug mode
      return Platform.isAndroid ? AdConfig.androidTestAdUnitId : AdConfig.iosTestAdUnitId;
    } else {
      // Use production ad unit IDs in release mode
      return Platform.isAndroid ? AdConfig.androidProductionAdUnitId : AdConfig.iosProductionAdUnitId;
    }
  }

  String get _rewardedAdUnitId => AdConfig.rewardedAdUnitId;
  
  Future<void> _loadInterstitialAd() async {
    if (_isAdLoaded || _isShowingAd || _adUnitId.isEmpty) return;
    
    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;
            
            // Set up ad event listeners
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _onAdDismissed();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                if (kDebugMode) {
                  print('❌ Ad failed to show: $error');
                }
                _onAdDismissed();
              },
              onAdShowedFullScreenContent: (ad) {
                if (kDebugMode) {
                  print('📱 Ad showed full screen content');
                }
              },
            );
            
            if (kDebugMode) {
              print('✅ Interstitial ad loaded successfully');
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) {
              print('❌ Failed to load interstitial ad: $error');
            }
            _isAdLoaded = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading interstitial ad: $e');
      }
      _isAdLoaded = false;
    }
  }
  
  void _onAdDismissed() {
    _isShowingAd = false;
    _isAdLoaded = false;
    _interstitialAd = null;
    
    // Load the next ad
    _loadInterstitialAd();
  }

  // Load rewarded ad
  Future<void> _loadRewardedAd() async {
    if (_isRewardedAdLoaded || _rewardedAdUnitId.isEmpty) return;
    
    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            
            if (kDebugMode) {
              print('✅ Rewarded ad loaded successfully');
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (kDebugMode) {
              print('❌ Failed to load rewarded ad: $error');
            }
            _isRewardedAdLoaded = false;
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading rewarded ad: $e');
      }
      _isRewardedAdLoaded = false;
    }
  }

  // Show rewarded ad and return reward amount (0 if ad not shown or not completed)
  Future<int> showRewardedAd() async {
    if (!AdConfig.adsEnabled) {
      if (kDebugMode) {
        print('⚠️ Ads are disabled, cannot show ad');
      }
      return -1; // Return -1 to indicate ads are disabled
    }

    if (_isShowingAd) {
      if (kDebugMode) {
        print('⚠️ Cannot show rewarded ad: already showing an ad');
      }
      return -1; // Return -1 to indicate error
    }

    // Load ad if not loaded
    if (!_isRewardedAdLoaded) {
      if (kDebugMode) {
        print('📱 Loading rewarded ad...');
      }
      await _loadRewardedAd();
      
      // Wait for ad to load (up to configured timeout)
      int waitTime = 0;
      while (!_isRewardedAdLoaded && waitTime < AdConfig.rewardedAdLoadTimeoutMs) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitTime += 100;
      }
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      if (kDebugMode) {
        print('⚠️ Rewarded ad failed to load');
      }
      return -1; // Return -1 to indicate ad failed to load
    }

    int rewardAmount = 0;
    bool adCompleted = false;

    try {
      _isShowingAd = true;
      
      // Set up full screen content callback
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          if (kDebugMode) {
            print('📱 Rewarded ad dismissed');
          }
          _isShowingAd = false;
          _isRewardedAdLoaded = false;
          _rewardedAd = null;
          
          // Load next rewarded ad
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          if (kDebugMode) {
            print('❌ Rewarded ad failed to show: $error');
          }
          _isShowingAd = false;
          _isRewardedAdLoaded = false;
          _rewardedAd = null;
          
          // Load next rewarded ad
          _loadRewardedAd();
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardAmount = StoreBusinessRules.adRewardAmount;
          adCompleted = true;
          
          if (kDebugMode) {
            print('🎁 User earned reward: ${StoreBusinessRules.adRewardAmount} treats');
          }
        },
      );

      // Wait for ad to be dismissed
      while (_isShowingAd) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return rewardAmount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing rewarded ad: $e');
      }
      _isShowingAd = false;
      return 0;
    }
  }
  
  Future<bool> showAdIfAppropriate({required String trigger}) async {
    // ✅ ADDED: Check premium status first
    if (await PremiumUtils.instance.hasPremiumAccess()) {
      if (kDebugMode) {
        print('👑 Premium user - no ads shown');
      }
      return false;
    }

    if (!AdConfig.adsEnabled) {
      if (kDebugMode) {
        print('⚠️ Ads are disabled, skipping ad display');
      }
      return false;
    }
    
    if (_isShowingAd || !_isAdLoaded) {
      if (kDebugMode) {
        print('⚠️ Cannot show ad: isShowingAd=$_isShowingAd, isAdLoaded=$_isAdLoaded');
      }
      return false;
    }
    
    // Check if enough time has passed since last ad
    if (!await _canShowAdNow()) {
      if (kDebugMode) {
        print('⏰ Ad shown recently, skipping...');
      }
      return false;
    }
    
    try {
      _isShowingAd = true;
      await _interstitialAd!.show();
      
      // Record that we showed an ad
      await _recordAdShown();
      
      if (kDebugMode) {
        print('📱 Showing interstitial ad (trigger: $trigger)');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing ad: $e');
      }
      _isShowingAd = false;
      return false;
    }
  }
  
    Future<bool> _canShowAdNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAdTime = prefs.getInt('last_ad_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeSinceLastAd = currentTime - lastAdTime;
      final canShow = timeSinceLastAd >= _minTimeBetweenAds;

      if (kDebugMode) {
        print('⏰ Ad timing check:');
        print('   • Last ad shown: ${DateTime.fromMillisecondsSinceEpoch(lastAdTime * 1000)}');
        print('   • Current time: ${DateTime.fromMillisecondsSinceEpoch(currentTime * 1000)}');
        print('   • Time since last ad: ${timeSinceLastAd} seconds');
        print('   • Min time required: $_minTimeBetweenAds seconds');
        print('   • Can show ad? ${canShow ? "YES" : "NO"}');
      }

      return canShow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking ad timing: $e');
      }
      return true; // Default to allowing ads if there's an error
    }
  }
  
  Future<void> _recordAdShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt('last_ad_time', currentTime);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error recording ad shown time: $e');
      }
    }
  }
  
  // Show ad after session completion
  Future<void> showAdAfterSession() async {
    await showAdIfAppropriate(trigger: 'session_completion');
  }
  
  // Show ad after mental training completion
  Future<void> showAdAfterMentalTraining() async {
    await showAdIfAppropriate(trigger: 'mental_training_completion');
  }
  
  // Show ad after drill completion
  Future<void> showAdAfterDrillCompletion() async {
    await showAdIfAppropriate(trigger: 'drill_completion');
  }
  
    // Check if we should show ad on app open
  Future<bool> shouldShowAdOnAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appOpenCount = prefs.getInt('app_open_count') ?? 0;
      final newCount = appOpenCount + 1;

      // Save the new count
      await prefs.setInt('app_open_count', newCount);

      if (kDebugMode) {
        print('📱 App open count: $appOpenCount → $newCount');
        print('📱 Should show ad? ${newCount % _adsAfterEveryNOpens == 0 ? "YES" : "NO"} (every $_adsAfterEveryNOpens opens)');
      }

      // Show ad every N app opens
      return newCount % _adsAfterEveryNOpens == 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking app open count: $e');
      }
      return false;
    }
  }
  
  // Show ad on app open if appropriate
  Future<void> showAdOnAppOpenIfAppropriate() async {
    if (await shouldShowAdOnAppOpen()) {
      await showAdIfAppropriate(trigger: 'app_open');
    }
  }
  
  // Dispose resources
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    _isRewardedAdLoaded = false;
    _isShowingAd = false;
  }
}
