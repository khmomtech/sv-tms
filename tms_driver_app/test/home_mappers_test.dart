import 'package:flutter_test/flutter_test.dart';
import 'package:tms_driver_app/models/banner_model.dart';
import 'package:tms_driver_app/screens/shipment/home/home_mappers.dart';

void main() {
  group('mapCurrentTripVm', () {
    test('uses in-progress dispatch first and maps from/to fields', () {
      final vm = mapCurrentTripVm(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 84920,
            'from': <String, dynamic>{'name': 'Chicago'},
            'to': <String, dynamic>{'name': 'Denver'},
            'estimatedArrival': '2026-02-27T18:30:00',
            'progressPercent': 65,
            'remainingMiles': 320,
          }
        ],
        const <Map<String, dynamic>>[],
        emptyLoadLabel: 'Load #',
        unknownRouteLabel: 'No active trip',
        etaFallback: '--:--',
        progressFallback: 'fallback',
      );

      expect(vm, isNotNull);
      expect(vm!.loadNumber, 'Load #84920');
      expect(vm.routeLabel, 'Chicago -> Denver');
      expect(vm.progress, closeTo(0.65, 0.001));
      expect(vm.progressLabel, contains('320'));
    });

    test('falls back to stops when from/to missing', () {
      final vm = mapCurrentTripVm(
        const <Map<String, dynamic>>[],
        <Map<String, dynamic>>[
          <String, dynamic>{
            'dispatchNo': 'D-01',
            'stops': <dynamic>[
              <String, dynamic>{'locationName': 'Omaha'},
              <String, dynamic>{'locationName': 'Lincoln'},
            ],
            'progress': 0.3,
          }
        ],
        emptyLoadLabel: 'Load #',
        unknownRouteLabel: 'No active trip',
        etaFallback: '--:--',
        progressFallback: 'fallback progress',
      );

      expect(vm, isNotNull);
      expect(vm!.loadNumber, 'Load #D-01');
      expect(vm.routeLabel, 'Omaha -> Lincoln');
      expect(vm.etaLabel, '--:--');
      expect(vm.progress, closeTo(0.3, 0.001));
      expect(vm.progressLabel, 'fallback progress');
    });
  });

  group('mapBannersToUpdates', () {
    test('returns Khmer title/subtitle when locale is Khmer and fields exist',
        () {
      final now = DateTime(2026, 2, 27);
      final items = mapBannersToUpdates(
        <BannerModel>[
          BannerModel(
            id: 1,
            title: 'EN Title',
            titleKh: 'KM Title',
            subtitle: 'EN Sub',
            subtitleKh: 'KM Sub',
            imageUrl: 'https://example.com/a.jpg',
            targetUrl: '/daily-summary',
            category: 'news',
            displayOrder: 1,
            active: true,
            viewCount: 0,
            clickCount: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        isKhmer: true,
        fallbackTitle: 'Fallback T',
        fallbackSubtitle: 'Fallback S',
        fallbackImageUrl: 'https://example.com/fallback.jpg',
      );

      expect(items, hasLength(1));
      expect(items.first.title, 'KM Title');
      expect(items.first.subtitle, 'KM Sub');
    });

    test('falls back when all banners have empty imageUrl', () {
      final now = DateTime(2026, 2, 27);
      final items = mapBannersToUpdates(
        <BannerModel>[
          BannerModel(
            id: 2,
            title: 'EN',
            subtitle: 'SUB',
            imageUrl: '',
            targetUrl: null,
            category: 'news',
            displayOrder: 1,
            active: true,
            viewCount: 0,
            clickCount: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        isKhmer: false,
        fallbackTitle: 'Fallback T',
        fallbackSubtitle: 'Fallback S',
        fallbackImageUrl: 'https://example.com/fallback.jpg',
      );

      expect(items, hasLength(1));
      expect(items.first.title, 'Fallback T');
      expect(items.first.imageUrl, 'https://example.com/fallback.jpg');
    });

    test('returns app fallback when banner list is empty', () {
      final items = mapBannersToUpdates(
        const <BannerModel>[],
        isKhmer: false,
        fallbackTitle: 'Fallback T',
        fallbackSubtitle: 'Fallback S',
        fallbackImageUrl: 'https://example.com/fallback.jpg',
      );

      expect(items, hasLength(1));
      expect(items.first.title, 'Fallback T');
      expect(items.first.subtitle, 'Fallback S');
      expect(items.first.imageUrl, 'https://example.com/fallback.jpg');
    });
  });
}
