import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/home_layout_section_model.dart';

/// Service for fetching home screen layout configuration from backend
class HomeLayoutService {
  // Shorter cache to make admin config changes reflect faster in driver app
  // while still avoiding excessive network traffic.
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<HomeLayoutSectionModel>? _cachedLayout;
  DateTime? _cacheTime;

  /// Fetch layout configuration from API
  /// Returns list of visible sections ordered by displayOrder
  Future<List<HomeLayoutSectionModel>> fetchLayout() async {
    // Return cached data if still fresh
    if (_cachedLayout != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheDuration) {
        debugPrint('[HomeLayout] Using cached layout (${age.inHours}h old)');
        return _cachedLayout!;
      }
    }

    try {
      // Try public endpoint first (no auth required)
      final publicResponse = await http.get(
        ApiConstants.endpoint('/driver/home-layout/sections'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (publicResponse.statusCode == 200) {
        final jsonResponse =
            json.decode(publicResponse.body) as Map<String, dynamic>;

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return _processLayoutResponse(jsonResponse['data']);
        }
      }

      // Fallback to authenticated endpoint
      final token = await ApiConstants.ensureFreshAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('[HomeLayout] No token, returning default layout');
        return _getDefaultLayout();
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/driver/home-layout/sections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return _processLayoutResponse(jsonResponse['data']);
        }
      }

      debugPrint('[HomeLayout] API returned non-success, using default layout');
      return _getDefaultLayout();
    } catch (e) {
      debugPrint('[HomeLayout] Error fetching layout: $e');
      // Return cached data if available, even if expired
      if (_cachedLayout != null) {
        debugPrint('[HomeLayout] Returning stale cache');
        return _cachedLayout!;
      }
      return _getDefaultLayout();
    }
  }

  /// Process API response and cache result
  List<HomeLayoutSectionModel> _processLayoutResponse(dynamic data) {
    final List<dynamic> sectionsJson = data as List<dynamic>;
    final sections = sectionsJson
        .map((json) =>
            HomeLayoutSectionModel.fromJson(json as Map<String, dynamic>))
        .where((s) => s.visible)
        .toList();

    // Sort by display order
    sections.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // Cache the result
    _cachedLayout = sections;
    _cacheTime = DateTime.now();

    debugPrint('[HomeLayout] Fetched ${sections.length} visible sections');
    return sections;
  }

  /// Get default layout if API fails
  /// Returns all sections in default order
  List<HomeLayoutSectionModel> _getDefaultLayout() {
    const defaultSections = [
      HomeLayoutSectionModel(
        sectionKey: HomeSectionKey.header,
        displayOrder: 0,
        visible: true,
      ),
      HomeLayoutSectionModel(
        sectionKey: HomeSectionKey.maintenanceBanner,
        displayOrder: 1,
        visible: true,
      ),
      HomeLayoutSectionModel(
        sectionKey: HomeSectionKey.shiftStatus,
        displayOrder: 2,
        visible: false,
      ),
      HomeLayoutSectionModel(
        sectionKey: HomeSectionKey.safetyStatus,
        displayOrder: 3,
        visible: true,
      ),
      HomeLayoutSectionModel(
        sectionKey: HomeSectionKey.importantUpdates,
        displayOrder: 4,
        visible: true,
      ),
      HomeLayoutSectionModel(
        sectionKey: HomeSectionKey.currentTrip,
        displayOrder: 5,
        visible: true,
      ),
      HomeLayoutSectionModel(
        sectionKey: HomeSectionKey.quickActions,
        displayOrder: 6,
        visible: true,
      ),
    ];

    debugPrint(
        '[HomeLayout] Using default layout with ${defaultSections.length} sections');
    return defaultSections;
  }

  /// Clear cache (useful for debugging or after config changes)
  void clearCache() {
    _cachedLayout = null;
    _cacheTime = null;
    debugPrint('[HomeLayout] Cache cleared');
  }

  /// Check if a specific section is visible according to layout config
  bool isSectionVisible(
      String sectionKey, List<HomeLayoutSectionModel> layout) {
    final section = layout.firstWhere(
      (s) => s.sectionKey == sectionKey,
      orElse: () => const HomeLayoutSectionModel(
        sectionKey: '',
        displayOrder: 999,
        visible: false,
      ),
    );
    return section.visible;
  }

  /// Get display order for a section
  int getSectionOrder(String sectionKey, List<HomeLayoutSectionModel> layout) {
    final section = layout.firstWhere(
      (s) => s.sectionKey == sectionKey,
      orElse: () => const HomeLayoutSectionModel(
        sectionKey: '',
        displayOrder: 999,
        visible: true,
      ),
    );
    return section.displayOrder;
  }
}
