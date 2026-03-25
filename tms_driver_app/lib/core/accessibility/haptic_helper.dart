import 'package:flutter/services.dart';

/// Utility class for providing haptic feedback throughout the app
/// Uses different feedback types based on action importance and context
class HapticHelper {
  /// Light haptic feedback for subtle interactions
  /// Use for: Minor UI interactions, list scrolling, small button taps
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }
  
  /// Medium haptic feedback for standard interactions
  /// Use for: Button taps, toggle switches, form submissions
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Heavy haptic feedback for important interactions
  /// Use for: Critical actions, confirmations, major state changes
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }
  
  /// Selection feedback for scrolling through discrete values
  /// Use for: Picker wheels, sliders, page indicators
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
  
  /// Vibration feedback for errors and warnings
  /// Use for: Error messages, validation failures, warnings
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }
  
  // ==================== Context-Specific Haptics ====================
  
  /// Login/logout actions
  static Future<void> authentication() async {
    await heavy();
  }
  
  /// Job/dispatch acceptance
  static Future<void> jobAccept() async {
    await heavy();
  }
  
  /// Job/dispatch decline
  static Future<void> jobDecline() async {
    await medium();
  }
  
  /// Status change (online/offline/busy)
  static Future<void> statusChange() async {
    await medium();
  }
  
  /// Navigation between screens
  static Future<void> navigation() async {
    await light();
  }
  
  /// Form submission success
  static Future<void> success() async {
    await heavy();
  }
  
  /// Form validation error
  static Future<void> validationError() async {
    await error();
  }
  
  /// Delete/remove action
  static Future<void> delete() async {
    await heavy();
  }
  
  /// Photo capture or file upload
  static Future<void> capture() async {
    await medium();
  }
  
  /// Pull to refresh
  static Future<void> refresh() async {
    await light();
  }
  
  /// Settings toggle
  static Future<void> toggle() async {
    await light();
  }
  
  /// Notification received
  static Future<void> notification() async {
    await medium();
  }
  
  /// Location tracking start/stop
  static Future<void> trackingToggle() async {
    await medium();
  }
  
  /// Emergency/SOS button
  static Future<void> emergency() async {
    await heavy();
    // Double haptic for emergency actions
    await Future.delayed(const Duration(milliseconds: 100));
    await heavy();
  }
  
  /// Button press (generic)
  static Future<void> buttonPress() async {
    await light();
  }
  
  /// Swipe action completed
  static Future<void> swipeComplete() async {
    await medium();
  }
  
  /// Dialog dismiss
  static Future<void> dismiss() async {
    await light();
  }
  
  /// Camera shutter
  static Future<void> shutter() async {
    await medium();
  }
  
  /// Document signature complete
  static Future<void> signatureComplete() async {
    await medium();
  }
  
  /// Timer/countdown start
  static Future<void> timerStart() async {
    await light();
  }
  
  /// Timer/countdown end
  static Future<void> timerEnd() async {
    await heavy();
  }
}
