import 'package:flutter_test/flutter_test.dart';
import 'package:bravoball_flutter/config/purchase_config.dart';

void main() {
  group('PurchaseConfig - Package ID to Product ID Mapping', () {
    test('getProductIdFromPackageId maps treat packages correctly', () {
      expect(
        PurchaseConfig.getProductIdFromPackageId(PurchaseConfig.treats500PackageId),
        PurchaseConfig.treats500ProductId,
      );
      expect(
        PurchaseConfig.getProductIdFromPackageId(PurchaseConfig.treats1000PackageId),
        PurchaseConfig.treats1000ProductId,
      );
      expect(
        PurchaseConfig.getProductIdFromPackageId(PurchaseConfig.treats2000PackageId),
        PurchaseConfig.treats2000ProductId,
      );
    });

    test('getProductIdFromPackageId maps premium packages correctly', () {
      expect(
        PurchaseConfig.getProductIdFromPackageId(PurchaseConfig.premiumMonthlyPackageId),
        PurchaseConfig.premiumMonthlyProductId,
      );
      expect(
        PurchaseConfig.getProductIdFromPackageId(PurchaseConfig.premiumYearlyPackageId),
        PurchaseConfig.premiumYearlyProductId,
      );
    });

    test('getProductIdFromPackageId throws exception for unknown package', () {
      expect(
        () => PurchaseConfig.getProductIdFromPackageId('UnknownPackage'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PurchaseConfig - Treat Amount Mapping', () {
    test('getTreatAmountFromPackageId returns correct amounts for treat packages', () {
      expect(
        PurchaseConfig.getTreatAmountFromPackageId(PurchaseConfig.treats500PackageId),
        PurchaseConfig.treats500Amount,
      );
      expect(
        PurchaseConfig.getTreatAmountFromPackageId(PurchaseConfig.treats1000PackageId),
        PurchaseConfig.treats1000Amount,
      );
      expect(
        PurchaseConfig.getTreatAmountFromPackageId(PurchaseConfig.treats2000PackageId),
        PurchaseConfig.treats2000Amount,
      );
    });

    test('getTreatAmountFromPackageId returns 0 for premium packages', () {
      expect(
        PurchaseConfig.getTreatAmountFromPackageId(PurchaseConfig.premiumMonthlyPackageId),
        0,
      );
      expect(
        PurchaseConfig.getTreatAmountFromPackageId(PurchaseConfig.premiumYearlyPackageId),
        0,
      );
    });

    test('getTreatAmountFromPackageId returns 0 for unknown package', () {
      expect(
        PurchaseConfig.getTreatAmountFromPackageId('UnknownPackage'),
        0,
      );
    });
  });

  group('PurchaseConfig - Package Type Validation', () {
    test('isTreatPackage returns true for treat packages', () {
      expect(
        PurchaseConfig.isTreatPackage(PurchaseConfig.treats500PackageId),
        true,
      );
      expect(
        PurchaseConfig.isTreatPackage(PurchaseConfig.treats1000PackageId),
        true,
      );
      expect(
        PurchaseConfig.isTreatPackage(PurchaseConfig.treats2000PackageId),
        true,
      );
    });

    test('isTreatPackage returns false for premium packages', () {
      expect(
        PurchaseConfig.isTreatPackage(PurchaseConfig.premiumMonthlyPackageId),
        false,
      );
      expect(
        PurchaseConfig.isTreatPackage(PurchaseConfig.premiumYearlyPackageId),
        false,
      );
    });

    test('isTreatPackage returns false for unknown package', () {
      expect(
        PurchaseConfig.isTreatPackage('UnknownPackage'),
        false,
      );
    });

    test('isPremiumPackage returns true for premium packages', () {
      expect(
        PurchaseConfig.isPremiumPackage(PurchaseConfig.premiumMonthlyPackageId),
        true,
      );
      expect(
        PurchaseConfig.isPremiumPackage(PurchaseConfig.premiumYearlyPackageId),
        true,
      );
    });

    test('isPremiumPackage returns false for treat packages', () {
      expect(
        PurchaseConfig.isPremiumPackage(PurchaseConfig.treats500PackageId),
        false,
      );
      expect(
        PurchaseConfig.isPremiumPackage(PurchaseConfig.treats1000PackageId),
        false,
      );
      expect(
        PurchaseConfig.isPremiumPackage(PurchaseConfig.treats2000PackageId),
        false,
      );
    });

    test('isPremiumPackage returns false for unknown package', () {
      expect(
        PurchaseConfig.isPremiumPackage('UnknownPackage'),
        false,
      );
    });
  });

  group('PurchaseConfig - List Getters', () {
    test('getTreatPackageIds returns all treat package IDs', () {
      final treatPackages = PurchaseConfig.getTreatPackageIds();
      expect(treatPackages.length, 3);
      expect(treatPackages, contains(PurchaseConfig.treats500PackageId));
      expect(treatPackages, contains(PurchaseConfig.treats1000PackageId));
      expect(treatPackages, contains(PurchaseConfig.treats2000PackageId));
    });

    test('getTreatProductIds returns all treat product IDs', () {
      final treatProducts = PurchaseConfig.getTreatProductIds();
      expect(treatProducts.length, 3);
      expect(treatProducts, contains(PurchaseConfig.treats500ProductId));
      expect(treatProducts, contains(PurchaseConfig.treats1000ProductId));
      expect(treatProducts, contains(PurchaseConfig.treats2000ProductId));
    });

    test('getPremiumPackageIds returns all premium package IDs', () {
      final premiumPackages = PurchaseConfig.getPremiumPackageIds();
      expect(premiumPackages.length, 2);
      expect(premiumPackages, contains(PurchaseConfig.premiumMonthlyPackageId));
      expect(premiumPackages, contains(PurchaseConfig.premiumYearlyPackageId));
    });

    test('getPremiumProductIds returns all premium product IDs', () {
      final premiumProducts = PurchaseConfig.getPremiumProductIds();
      expect(premiumProducts.length, 2);
      expect(premiumProducts, contains(PurchaseConfig.premiumMonthlyProductId));
      expect(premiumProducts, contains(PurchaseConfig.premiumYearlyProductId));
    });
  });

  group('PurchaseConfig - Constants Validation', () {
    test('treat amounts are correct', () {
      expect(PurchaseConfig.treats500Amount, 500);
      expect(PurchaseConfig.treats1000Amount, 1000);
      expect(PurchaseConfig.treats2000Amount, 2000);
    });

    test('offering IDs are correct', () {
      expect(PurchaseConfig.defaultOfferingId, 'default');
      expect(PurchaseConfig.treatsOfferingId, 'bravoball_treats');
    });

    test('package identifiers match expected values', () {
      expect(PurchaseConfig.treats500PackageId, 'Treats500');
      expect(PurchaseConfig.treats1000PackageId, 'Treats1000');
      expect(PurchaseConfig.treats2000PackageId, 'Treats2000');
      expect(PurchaseConfig.premiumMonthlyPackageId, 'PremiumMonthly');
      expect(PurchaseConfig.premiumYearlyPackageId, 'PremiumYearly');
    });
  });
}

