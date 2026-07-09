import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixigo/api.dart';

void main() {
  group('Api.resolveBaseUrl', () {
    test('uses localhost for web', () {
      expect(
        Api.resolveBaseUrl(isWeb: true, platform: TargetPlatform.windows),
        'http://localhost:3000',
      );
    });

    test('uses Android emulator host for Android', () {
      expect(
        Api.resolveBaseUrl(isWeb: false, platform: TargetPlatform.android),
        'http://10.0.2.2:3000',
      );
    });

    test('honors an explicit override', () {
      expect(
        Api.resolveBaseUrl(override: 'http://127.0.0.1:4000', isWeb: false, platform: TargetPlatform.iOS),
        'http://127.0.0.1:4000',
      );
    });
  });
}
