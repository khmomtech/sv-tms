import 'package:flutter_test/flutter_test.dart';
import 'package:tms_driver_app/utils/banner_navigation.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

void main() {
  group('resolveBannerTarget', () {
    test('maps slug to internal route', () {
      final res = resolveBannerTarget('/trip-report', baseUrl: 'https://api.example.com');
      expect(res.type, BannerNavType.internalRoute);
      expect(res.route, AppRoutes.tripReport);
    });

    test('handles banner-article slug with id and url', () {
      final res = resolveBannerTarget('banner-article?id=123&url=https://example.com/post',
          baseUrl: 'https://api.example.com');
      expect(res.type, BannerNavType.bannerArticle);
      expect(res.articleId, '123');
      expect(res.articleUrl.toString(), 'https://example.com/post');
    });

    test('falls back to external url', () {
      final res = resolveBannerTarget('https://example.com/news');
      expect(res.type, BannerNavType.externalUrl);
      expect(res.url.toString(), 'https://example.com/news');
    });

    test('invalid when empty', () {
      final res = resolveBannerTarget('   ');
      expect(res.type, BannerNavType.invalid);
    });
  });
}
