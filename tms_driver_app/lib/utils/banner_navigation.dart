import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

enum BannerNavType { internalRoute, externalUrl, bannerArticle, invalid }

class BannerNavResolution {
  final BannerNavType type;
  final String? route;
  final Uri? url;
  final String? articleId;
  final Uri? articleUrl;

  const BannerNavResolution._({
    required this.type,
    this.route,
    this.url,
    this.articleId,
    this.articleUrl,
  });

  factory BannerNavResolution.internal(String route) =>
      BannerNavResolution._(type: BannerNavType.internalRoute, route: route);

  factory BannerNavResolution.external(Uri url) =>
      BannerNavResolution._(type: BannerNavType.externalUrl, url: url);

  factory BannerNavResolution.article({String? id, Uri? articleUrl}) =>
      BannerNavResolution._(
          type: BannerNavType.bannerArticle, articleId: id, articleUrl: articleUrl);

  factory BannerNavResolution.invalid() =>
      const BannerNavResolution._(type: BannerNavType.invalid);
}

/// Resolve a banner target into an action (internal route, external URL, or banner article).
/// This keeps logic deterministic and testable.
BannerNavResolution resolveBannerTarget(
  String target, {
  String? baseUrl,
}) {
  final trimmed = target.trim();
  if (trimmed.isEmpty) return BannerNavResolution.invalid();

  final lower = trimmed.toLowerCase();
  // Normalize base URL
  final base = baseUrl?.isNotEmpty == true ? baseUrl! : ApiConstants.baseUrl;

  // Map known slugs to internal routes
  String normalizedSlug(String value) {
    return value.startsWith('/') ? value.substring(1) : value;
  }

  final slug = normalizedSlug(lower);
  switch (slug) {
    case 'daily-summary':
      return BannerNavResolution.internal(AppRoutes.dailySummary);
    case 'trip-report':
      return BannerNavResolution.internal(AppRoutes.tripReport);
    case 'report-issue-list':
      return BannerNavResolution.internal(AppRoutes.reportIssueList);
    case 'my-vehicle':
      return BannerNavResolution.internal(AppRoutes.myVehicle);
    case 'my-id-card':
      return BannerNavResolution.internal(AppRoutes.myIdCard);
    case 'dashboard':
      return BannerNavResolution.internal(AppRoutes.dashboard);
  }

  // Banner article slug handling: "banner-article?id=123" or "/banner-article?id=123"
  if (slug.startsWith('banner-article')) {
    final uri = _safeParseUri(slug);
    final id = uri?.queryParameters['id'];
    final urlParam = uri?.queryParameters['url'];
    Uri? articleUrl;
    if (urlParam != null && urlParam.isNotEmpty) {
      articleUrl = _safeParseAbsolute(urlParam) ?? _prependBase(urlParam, base);
    }
    return BannerNavResolution.article(id: id, articleUrl: articleUrl);
  }

  // Internal route starting with slash (not mapped above)
  if (trimmed.startsWith('/')) {
    return BannerNavResolution.internal(trimmed);
  }

  // External full URL
  final absolute = _safeParseAbsolute(trimmed);
  if (absolute != null) return BannerNavResolution.external(absolute);

  // Relative URL → treat as external with base
  final withBase = _prependBase(trimmed, base);
  if (withBase != null) return BannerNavResolution.external(withBase);

  return BannerNavResolution.invalid();
}

Uri? _safeParseUri(String value) {
  try {
    // Allow parsing without scheme by prefixing dummy scheme
    final prefixed =
        value.contains('://') ? value : 'https://placeholder.local/$value';
    return Uri.tryParse(prefixed);
  } catch (_) {
    return null;
  }
}

Uri? _safeParseAbsolute(String value) {
  try {
    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return uri;
    }
    return null;
  } catch (_) {
    return null;
  }
}

Uri? _prependBase(String value, String baseUrl) {
  try {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedValue =
        value.startsWith('/') ? value : '/$value';
    return Uri.tryParse('$normalizedBase$normalizedValue');
  } catch (_) {
    return null;
  }
}
