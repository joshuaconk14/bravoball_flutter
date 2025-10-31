import 'package:integration_test/integration_test_driver.dart';

/// Integration test driver
/// 
/// This file enables running integration tests with:
///   flutter drive --driver=integration_test/driver.dart --target=integration_test/app_test.dart
Future<void> main() => integrationDriver();
