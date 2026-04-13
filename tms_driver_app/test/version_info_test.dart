import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tms_driver_app/models/version_info.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  VersionInfo buildInfo() {
    return VersionInfo.fromJson({
      'latestVersion': '2.0.0',
      'mandatoryUpdate': false,
      'playstoreUrl': 'https://play.example/app',
      'appstoreUrl': 'https://apps.example/app',
      'releaseNoteEn': 'Global EN',
      'releaseNoteKm': 'Global KM',
      'androidLatestVersion': '2.1.0',
      'androidMandatoryUpdate': true,
      'androidReleaseNoteEn': 'Android EN',
      'androidReleaseNoteKm': 'Android KM',
      'iosLatestVersion': '2.2.0',
      'iosMandatoryUpdate': true,
      'iosReleaseNoteEn': 'iOS EN',
      'iosReleaseNoteKm': 'iOS KM',
    });
  }

  test('uses android override when running on android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final info = buildInfo();

    expect(info.effectiveLatestVersion, '2.1.0');
    expect(info.effectiveMandatoryUpdate, isTrue);
    expect(info.effectiveReleaseNote(isKhmer: false), 'Android EN');
    expect(info.effectiveStoreUrl, 'https://play.example/app');
  });

  test('uses ios override when running on ios', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final info = buildInfo();

    expect(info.effectiveLatestVersion, '2.2.0');
    expect(info.effectiveMandatoryUpdate, isTrue);
    expect(info.effectiveReleaseNote(isKhmer: true), 'iOS KM');
    expect(info.effectiveStoreUrl, 'https://apps.example/app');
  });

  test('falls back to global values when no platform override exists', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final info = VersionInfo.fromJson({
      'latestVersion': '3.0.0',
      'mandatoryUpdate': true,
      'playstoreUrl': 'https://play.example/global',
      'releaseNoteEn': 'Global only',
    });

    expect(info.effectiveLatestVersion, '3.0.0');
    expect(info.effectiveMandatoryUpdate, isTrue);
    expect(info.effectiveReleaseNote(isKhmer: false), 'Global only');
    expect(info.effectiveStoreUrl, 'https://play.example/global');
  });
}
