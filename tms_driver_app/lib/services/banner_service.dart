import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/network/api_constants.dart';
import '../models/banner_model.dart';

class BannerService {
  // Simple cache to prevent duplicate fetches
  List<BannerModel>? _cachedBanners;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 1);

  String _normalizeUrl(String? v) {
    if (v == null || v.isEmpty) return '';
    final s = v.trim();

    // Filter out blob URLs (Angular frontend temporary URLs)
    if (s.startsWith('blob:')) {
      return '';
    }

    // Allow full HTTP/HTTPS URLs (including external CDNs)
    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    // Handle relative paths
    if (s.startsWith('/uploads')) return '${ApiConstants.imageUrl}$s';
    if (s.startsWith('uploads/')) return '${ApiConstants.imageUrl}/$s';

    // bare filename with common image extensions → assume banners folder
    final lower = s.toLowerCase();
    final isFile = lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg');
    if (isFile && !s.contains('/')) {
      return '${ApiConstants.imageUrl}/uploads/images/banners/$s';
    }
    return s;
  }

  /// Fetch all active banners
  Future<List<BannerModel>> fetchActiveBanners({bool forceRefresh = false}) async {
    // Return cached data if still fresh and not forced
    if (!forceRefresh && _cachedBanners != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheDuration) {
        debugPrint('[Banner] Using cached data (${age.inSeconds}s old)');
        return _cachedBanners!;
      }
    }

    try {
      // Try public endpoint first (no auth required)
      final publicResponse = await http.get(
        ApiConstants.endpoint('/driver/banners/active'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (publicResponse.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            json.decode(publicResponse.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return await _processBannerResponse(jsonResponse['data']);
        }
      }

      // Fallback to authenticated endpoint
      final token = await ApiConstants.ensureFreshAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('[Banner] No token, returning empty list');
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/driver/banners/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return await _processBannerResponse(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load banners');
        }
      } else if (response.statusCode == 401) {
        debugPrint('[Banner] Unauthorized, returning empty list');
        return [];
      } else {
        throw Exception('Failed to load banners: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      // Return cached data if available, even if expired
      if (_cachedBanners != null) {
        debugPrint('[Banner] Using stale cache due to error');
        return _cachedBanners!;
      }
      return [];
    }
  }

  /// Process banner response data
  Future<List<BannerModel>> _processBannerResponse(dynamic data) async {
    final List<dynamic> bannersJson = data as List<dynamic>;
    final list = bannersJson
        .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Normalize image URLs defensively
    final normalized = list
        .map((b) => BannerModel(
              id: b.id,
              title: b.title,
              titleKh: b.titleKh,
              subtitle: b.subtitle,
              subtitleKh: b.subtitleKh,
              imageUrl: _normalizeUrl(b.imageUrl),
              targetUrl: b.targetUrl,
              category: b.category,
              displayOrder: b.displayOrder,
              active: b.active,
              startDate: b.startDate,
              endDate: b.endDate,
              viewCount: b.viewCount,
              clickCount: b.clickCount,
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            ))
        .where((b) => b.imageUrl != null && b.imageUrl!.isNotEmpty)
        .toList();

    // Cache normalized results without network availability pre-check.
    // Image widgets already handle load/failure gracefully with errorBuilder.
    _cachedBanners = normalized;
    _cacheTime = DateTime.now();

    debugPrint('[Banner] Fetched ${normalized.length} banner(s)');
    return normalized;
  }

  /// Fetch active banners by category
  Future<List<BannerModel>> fetchBannersByCategory(String category) async {
    try {
      final token = await ApiConstants.ensureFreshAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/driver/banners/category/$category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> bannersJson =
              jsonResponse['data'] as List<dynamic>;
          final list = bannersJson
              .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return list
              .map((b) => BannerModel(
                    id: b.id,
                    title: b.title,
                    titleKh: b.titleKh,
                    subtitle: b.subtitle,
                    subtitleKh: b.subtitleKh,
                    imageUrl: _normalizeUrl(b.imageUrl),
                    targetUrl: b.targetUrl,
                    category: b.category,
                    displayOrder: b.displayOrder,
                    active: b.active,
                    startDate: b.startDate,
                    endDate: b.endDate,
                    viewCount: b.viewCount,
                    clickCount: b.clickCount,
                    createdAt: b.createdAt,
                    updatedAt: b.updatedAt,
                  ))
              .where((b) =>
                  b.imageUrl != null &&
                  b.imageUrl!.isNotEmpty) // Filter out invalid URLs
              .toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load banners');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to load banners: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching banners by category: $e');
      rethrow;
    }
  }

  /// Track banner click (analytics)
  Future<void> trackBannerClick(int bannerId) async {
    try {
      final token = await ApiConstants.getAccessToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('Warning: No auth token, skipping click tracking');
        }
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/driver/banners/$bannerId/click'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('Banner click tracked successfully for banner $bannerId');
        }
      } else {
        if (kDebugMode) {
          debugPrint('Failed to track banner click: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Don't throw - click tracking is non-critical
      if (kDebugMode) debugPrint('Error tracking banner click: $e');
    }
  }
}
