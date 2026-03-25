// lib/core/utils/version_utils.dart

class VersionUtils {
  /// Compares two version strings (e.g., '1.2.0', '1.10.5').
  /// Returns true if version1 is less than version2.
  /// Handles versions with different numbers of components.
  static bool isVersionLessThan(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      final length = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

      for (var i = 0; i < length; i++) {
        final v1 = i < v1Parts.length ? v1Parts[i] : 0;
        final v2 = i < v2Parts.length ? v2Parts[i] : 0;

        if (v1 < v2) {
          return true;
        }
        if (v1 > v2) {
          return false;
        }
      }
      return false; // versions are equal
    } catch (e) {
      // If parsing fails, assume no update is needed to avoid blocking the user.
      return false;
    }
  }
}
