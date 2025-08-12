import 'package:flutter/foundation.dart';

/// Premium subscription status
enum PremiumStatus {
  free,
  premium,
  trial,
  expired,
}

/// Premium features that can be gated
enum PremiumFeature {
  noAds,
  unlimitedDrills,
  unlimitedCustomDrills,
  unlimitedSessions,
  advancedAnalytics,
  basicDrills,
  weeklySummaries,
  monthlySummaries,
}

/// Subscription plan types
enum SubscriptionPlan {
  monthly,
  yearly,
  lifetime,
}

/// Subscription plan details
class SubscriptionPlanDetails {
  final SubscriptionPlan plan;
  final String name;
  final double price;
  final String currency;
  final int durationDays;
  final String? description;
  final List<String> features;
  final bool isPopular;
  final double? originalPrice; // For discounted plans

  const SubscriptionPlanDetails({
    required this.plan,
    required this.name,
    required this.price,
    this.currency = 'USD',
    required this.durationDays,
    this.description,
    required this.features,
    this.isPopular = false,
    this.originalPrice,
  });

  /// Get monthly equivalent price for yearly plans
  double get monthlyEquivalentPrice {
    if (plan == SubscriptionPlan.yearly) {
      return price / 12;
    }
    return price;
  }

  /// Get savings percentage for yearly plans
  double? get savingsPercentage {
    if (plan == SubscriptionPlan.yearly && originalPrice != null) {
      final yearlyOriginal = originalPrice! * 12;
      return ((yearlyOriginal - price) / yearlyOriginal) * 100;
    }
    return null;
  }

  /// Format price for display
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Format monthly equivalent price
  String get formattedMonthlyPrice {
    return '\$${monthlyEquivalentPrice.toStringAsFixed(2)}';
  }

  /// Get duration text
  String get durationText {
    switch (plan) {
      case SubscriptionPlan.monthly:
        return 'month';
      case SubscriptionPlan.yearly:
        return 'year';
      case SubscriptionPlan.lifetime:
        return 'lifetime';
    }
  }

  /// Get full duration text with price
  String get fullDurationText {
    if (plan == SubscriptionPlan.lifetime) {
      return 'One-time payment';
    }
    return 'per $durationText';
  }
}

/// Free feature usage tracking
class FreeFeatureUsage {
  final int customDrillsRemaining;
  final int sessionsRemaining;
  final int customDrillsUsed;
  final int sessionsUsed;

  const FreeFeatureUsage({
    required this.customDrillsRemaining,
    required this.sessionsRemaining,
    required this.customDrillsUsed,
    required this.sessionsUsed,
  });

  /// Check if user has any custom drills remaining
  bool get hasCustomDrillsRemaining => customDrillsRemaining > 0;

  /// Check if user has any sessions remaining
  bool get hasSessionsRemaining => sessionsRemaining > 0;

  /// Get custom drills progress percentage
  double get customDrillsProgress {
    const total = 3; // Free users get 3 custom drills per month
    return customDrillsUsed / total;
  }

  /// Get sessions progress percentage
  double get sessionsProgress {
    const total = 1; // Free users get 1 session per day
    return sessionsUsed / total;
  }

  /// Get custom drills progress text
  String get customDrillsProgressText {
    return '$customDrillsUsed of 3 used this month';
  }

  /// Get sessions progress text
  String get sessionsProgressText {
    return '$sessionsUsed of 1 used today';
  }
}

/// Premium subscription details
class PremiumSubscription {
  final String id;
  final PremiumStatus status;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final bool isActive;
  final bool isTrial;
  final String? platform; // 'ios', 'android', 'web'
  final String? receiptData; // For receipt validation

  const PremiumSubscription({
    required this.id,
    required this.status,
    required this.plan,
    required this.startDate,
    this.endDate,
    this.trialEndDate,
    required this.isActive,
    required this.isTrial,
    this.platform,
    this.receiptData,
  });

  /// Check if subscription is expired
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Check if subscription is in trial
  bool get inTrial {
    if (trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Get remaining trial days
  int? get remainingTrialDays {
    if (trialEndDate == null) return null;
    final remaining = trialEndDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Get subscription duration text
  String get durationText {
    switch (plan) {
      case SubscriptionPlan.monthly:
        return 'Monthly';
      case SubscriptionPlan.yearly:
        return 'Yearly';
      case SubscriptionPlan.lifetime:
        return 'Lifetime';
    }
  }

  /// Get status text for display
  String get statusText {
    switch (status) {
      case PremiumStatus.free:
        return 'Free';
      case PremiumStatus.premium:
        if (inTrial) {
          return 'Trial';
        }
        return 'Premium';
      case PremiumStatus.trial:
        return 'Trial';
      case PremiumStatus.expired:
        return 'Expired';
    }
  }

  /// Create from JSON
  factory PremiumSubscription.fromJson(Map<String, dynamic> json) {
    return PremiumSubscription(
      id: json['id'] as String,
      status: PremiumStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PremiumStatus.free,
      ),
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      trialEndDate: json['trialEndDate'] != null ? DateTime.parse(json['trialEndDate'] as String) : null,
      isActive: json['isActive'] as bool? ?? false,
      isTrial: json['isTrial'] as bool? ?? false,
      platform: json['platform'] as String?,
      receiptData: json['receiptData'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'plan': plan.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'isActive': isActive,
      'isTrial': isTrial,
      'platform': platform,
      'receiptData': receiptData,
    };
  }
}

/// Premium upgrade prompt data
class PremiumUpgradePrompt {
  final String title;
  final String description;
  final String? imagePath;
  final List<String> features;
  final String? ctaText;
  final bool showTrialOffer;
  final int? trialDays;

  const PremiumUpgradePrompt({
    required this.title,
    required this.description,
    this.imagePath,
    required this.features,
    this.ctaText,
    this.showTrialOffer = false,
    this.trialDays,
  });

  /// Get CTA text with trial offer
  String get displayCtaText {
    if (showTrialOffer && trialDays != null) {
      return 'Start $trialDays-Day Free Trial';
    }
    return ctaText ?? 'Upgrade to Premium';
  }
}

/// Premium analytics data
class PremiumAnalytics {
  final int totalSessions;
  final int totalCustomDrills;
  final int totalDrillsCompleted;
  final double averageSessionDuration;
  final DateTime lastSessionDate;
  final List<String> topDrillTypes;
  final Map<String, int> monthlyProgress;

  const PremiumAnalytics({
    required this.totalSessions,
    required this.totalCustomDrills,
    required this.totalDrillsCompleted,
    required this.averageSessionDuration,
    required this.lastSessionDate,
    required this.topDrillTypes,
    required this.monthlyProgress,
  });

  /// Get total time spent in sessions
  Duration get totalSessionTime {
    return Duration(minutes: (totalSessions * averageSessionDuration).round());
  }

  /// Get formatted total time
  String get formattedTotalTime {
    final hours = totalSessionTime.inHours;
    final minutes = totalSessionTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Get progress percentage for current month
  double get currentMonthProgress {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final monthKey = '${currentYear}_${currentMonth.toString().padLeft(2, '0')}';
    
    final currentMonthSessions = monthlyProgress[monthKey] ?? 0;
    // Assume goal is 30 sessions per month
    return (currentMonthSessions / 30).clamp(0.0, 1.0);
  }
}
