/// Pure business logic functions for store operations
/// These functions are testable without mocks or dependencies
class StoreBusinessRules {
  /// Cost of purchasing a streak freeze
  static const int streakFreezeCost = 50;
  
  /// Cost of purchasing a streak reviver
  static const int streakReviverCost = 100;

  /// Check if user has enough treats to purchase a streak freeze
  static bool canPurchaseStreakFreeze(int currentTreats) {
    return currentTreats >= streakFreezeCost;
  }

  /// Check if user has enough treats to purchase a streak reviver
  static bool canPurchaseStreakReviver(int currentTreats) {
    return currentTreats >= streakReviverCost;
  }

  /// Get the required treats amount for a streak freeze
  static int getRequiredTreatsForFreeze() {
    return streakFreezeCost;
  }

  /// Get the required treats amount for a streak reviver
  static int getRequiredTreatsForReviver() {
    return streakReviverCost;
  }

  /// Check if user has any streak freezes available
  static bool hasStreakFreezesAvailable(int streakFreezes) {
    return streakFreezes > 0;
  }

  /// Check if user has any streak revivers available
  static bool hasStreakReviversAvailable(int streakRevivers) {
    return streakRevivers > 0;
  }

  /// Calculate treats remaining after purchasing a streak freeze
  static int calculateTreatsAfterFreezePurchase(int currentTreats) {
    if (!canPurchaseStreakFreeze(currentTreats)) {
      return currentTreats; // Can't purchase, treats unchanged
    }
    return currentTreats - streakFreezeCost;
  }

  /// Calculate treats remaining after purchasing a streak reviver
  static int calculateTreatsAfterReviverPurchase(int currentTreats) {
    if (!canPurchaseStreakReviver(currentTreats)) {
      return currentTreats; // Can't purchase, treats unchanged
    }
    return currentTreats - streakReviverCost;
  }

  /// Validate a date string can be parsed (for freeze/reviver dates from API)
  static bool isValidDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return false;
    }
    
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Parse a date string safely, returns null if invalid
  static DateTime? parseDateSafely(String? dateString) {
    if (!isValidDateString(dateString)) {
      return null;
    }
    
    try {
      return DateTime.parse(dateString!);
    } catch (e) {
      return null;
    }
  }

  /// Check if a freeze date is still active (within last 24 hours)
  /// Returns true if freeze was used today or yesterday
  static bool isFreezeDateActive(DateTime? freezeDate, DateTime currentDate) {
    if (freezeDate == null) {
      return false;
    }
    
    final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final freezeDay = DateTime(freezeDate.year, freezeDate.month, freezeDate.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    return freezeDay == today || freezeDay == yesterday;
  }

  /// Check if a reviver date is valid (not expired)
  /// Revivers are typically valid for a longer period than freezes
  static bool isReviverDateValid(DateTime? reviverDate, DateTime currentDate) {
    if (reviverDate == null) {
      return false;
    }
    
    // Revivers are typically valid for 7 days
    final daysSinceReviver = currentDate.difference(reviverDate).inDays;
    return daysSinceReviver <= 7 && daysSinceReviver >= 0;
  }

  /// Validate treat amount is positive
  static bool isValidTreatAmount(int amount) {
    return amount >= 0;
  }

  /// Validate item count is non-negative
  static bool isValidItemCount(int count) {
    return count >= 0;
  }
}

