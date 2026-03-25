import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeErrorHandler {
  static String khmerError(List<String> failures) {
    final labels = <String>[];
    if (failures.contains('session')) labels.add('ចូលប្រព័ន្ធ');
    if (failures.contains('notifications')) labels.add('ការជូនដំណឹង');
    if (failures.contains('notifications_ws')) labels.add('WebSocket');
    if (failures.contains('dispatches')) labels.add('Trip/Dispatch');
    if (failures.contains('safety')) labels.add('Safety Check');
    if (failures.contains('vehicle')) labels.add('យានយន្ត');
    if (labels.isEmpty) return 'មិនអាចទាញយកទិន្នន័យបានទេ។';
    return 'មិនអាចទាញយកទិន្នន័យ៖ ${labels.join(", ")}';
  }

  static String apiErrorMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('timed out')) {
      return 'មិនអាចភ្ជាប់ទៅ API បានទេ។ សូមពិនិត្យ URL ឬ Backend។\nAPI: ${ApiConstants.baseUrl}';
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'សិទ្ធិមិនត្រឹមត្រូវ (Unauthorized)។ សូមចូលគណនីម្តងទៀត។';
    }
    if (lower.contains('not assigned to a driver') ||
        lower.contains('driver not found')) {
      return 'គណនីនេះមិនបានភ្ជាប់ជាមួយអ្នកបើកបរ។ សូមអោយ Admin បង្កើត/ភ្ជាប់ Driver Account ម្តងទៀត។';
    }
    return 'បញ្ហាក្នុងការភ្ជាប់ API: $raw';
  }
}
