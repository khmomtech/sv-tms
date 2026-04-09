# Accessibility Implementation Guide for Developers

This guide shows you how to apply accessibility patterns to screens throughout the app.

## 🎯 Quick Implementation Checklist

For each screen you work on:
- [ ] Add Semantics to all interactive elements
- [ ] Add haptic feedback to button actions
- [ ] Use theme colors (not hard-coded colors)
- [ ] Use theme text styles (not hard-coded sizes)
- [ ] Test with screen reader
- [ ] Test at 200% font scale

---

## 📱 Complete Screen Example

Here's a complete example showing all accessibility patterns:

```dart
import 'package:flutter/material.dart';
import 'package:tms_tms_driver_app/core/accessibility/haptic_helper.dart';
import 'package:tms_tms_driver_app/core/accessibility/app_colors.dart';

class AccessibleExampleScreen extends StatefulWidget {
  const AccessibleExampleScreen({super.key});

  @override
  State<AccessibleExampleScreen> createState() => _AccessibleExampleScreenState();
}

class _AccessibleExampleScreenState extends State<AccessibleExampleScreen> {
  bool _isEnabled = false;
  
  @override
  Widget build(BuildContext context) {
    // Get theme colors (auto-switches with dark mode)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessible Screen'),
        actions: [
          // Icon button with Semantics and haptic
          Semantics(
            label: 'Refresh',
            hint: 'Double tap to refresh data',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await HapticHelper.refresh();
                _handleRefresh();
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accessible heading
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              
              // Accessible card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Toggle with Semantics
                      Semantics(
                        label: 'Enable notifications',
                        hint: _isEnabled 
                          ? 'Notifications enabled. Double tap to disable'
                          : 'Notifications disabled. Double tap to enable',
                        toggled: _isEnabled,
                        child: SwitchListTile(
                          title: const Text('Notifications'),
                          subtitle: Text(
                            _isEnabled ? 'Enabled' : 'Disabled',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          value: _isEnabled,
                          onChanged: (value) {
                            HapticHelper.toggle();
                            setState(() => _isEnabled = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Primary action button
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'Submit form',
                  hint: 'Double tap to submit your changes',
                  button: true,
                  child: ElevatedButton(
                    onPressed: () async {
                      await HapticHelper.buttonPress();
                      _handleSubmit();
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Secondary action button
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'Cancel',
                  hint: 'Double tap to cancel and go back',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticHelper.dismiss();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Accessible image with label
              Semantics(
                label: 'Company logo',
                image: true,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  semanticLabel: 'Company logo',
                ),
              ),
              const SizedBox(height: 16),
              
              // Status indicator with semantic meaning
              Semantics(
                label: 'Status: ${_isEnabled ? "Active" : "Inactive"}',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isEnabled 
                      ? AppColors.getSuccess(isDark) 
                      : AppColors.textDisabledLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isEnabled ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleRefresh() {
    // Refresh logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshed')),
    );
  }
  
  void _handleSubmit() async {
    await HapticHelper.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted successfully')),
    );
  }
}
```

---

## 🔍 Pattern Breakdown

### 1. Accessible Button Pattern

```dart
Semantics(
  label: 'Button name',              // What it is
  hint: 'Action when double tapped', // What it does
  button: true,                       // Widget role
  child: ElevatedButton(
    onPressed: () async {
      await HapticHelper.buttonPress(); // Haptic feedback
      performAction();
    },
    child: Text(
      'Button Text',
      style: Theme.of(context).textTheme.labelLarge, // Theme style
    ),
  ),
)
```

### 2. Accessible Toggle Pattern

```dart
Semantics(
  label: 'Setting name',
  hint: isEnabled 
    ? 'Enabled. Double tap to disable' 
    : 'Disabled. Double tap to enable',
  toggled: isEnabled,
  child: Switch(
    value: isEnabled,
    onChanged: (value) {
      HapticHelper.toggle();
      updateSetting(value);
    },
  ),
)
```

### 3. Accessible Icon Button Pattern

```dart
Semantics(
  label: 'Action name',
  hint: 'Double tap to perform action',
  button: true,
  child: IconButton(
    icon: Icon(Icons.action),
    tooltip: 'Action name', // Also add tooltip
    onPressed: () async {
      await HapticHelper.buttonPress();
      performAction();
    },
  ),
)
```

### 4. Accessible List Item Pattern

```dart
Semantics(
  label: 'Item title',
  hint: 'Double tap to view details',
  button: true,
  child: ListTile(
    leading: Icon(Icons.item),
    title: Text(
      'Item Title',
      style: Theme.of(context).textTheme.titleMedium,
    ),
    subtitle: Text(
      'Item description',
      style: Theme.of(context).textTheme.bodySmall,
    ),
    trailing: Icon(Icons.chevron_right),
    onTap: () {
      HapticHelper.navigation();
      Navigator.push(...);
    },
  ),
)
```

### 5. Accessible Image Pattern

```dart
Semantics(
  label: 'Image description',
  image: true,
  child: Image.network(
    imageUrl,
    semanticLabel: 'Detailed image description',
    errorBuilder: (context, error, stackTrace) {
      return Semantics(
        label: 'Image failed to load',
        child: Icon(Icons.broken_image),
      );
    },
  ),
)
```

### 6. Accessible Form Field Pattern

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Field Label',
    hintText: 'Enter value',
    // These are automatically accessible
  ),
  style: Theme.of(context).textTheme.bodyLarge,
  validator: (value) {
    // Return error message for screen readers
    if (value?.isEmpty ?? true) {
      return 'This field is required';
    }
    return null;
  },
  onChanged: (value) {
    // Optional: haptic on error
    if (value.isEmpty) {
      HapticHelper.validationError();
    }
  },
)
```

### 7. Accessible Dialog Pattern

```dart
Future<void> showAccessibleDialog(BuildContext context) async {
  await HapticHelper.buttonPress();
  
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Dialog Title'),
      content: Text('Dialog message'),
      actions: [
        Semantics(
          label: 'Cancel button',
          hint: 'Double tap to cancel',
          button: true,
          child: TextButton(
            onPressed: () {
              HapticHelper.dismiss();
              Navigator.pop(ctx);
            },
            child: Text('Cancel'),
          ),
        ),
        Semantics(
          label: 'Confirm button',
          hint: 'Double tap to confirm action',
          button: true,
          child: ElevatedButton(
            onPressed: () async {
              await HapticHelper.success();
              Navigator.pop(ctx);
              performAction();
            },
            child: Text('Confirm'),
          ),
        ),
      ],
    ),
  );
}
```

### 8. Accessible Status Badge Pattern

```dart
Widget buildStatusBadge(String status, bool isDark) {
  final Color statusColor;
  final String statusLabel;
  
  switch (status.toLowerCase()) {
    case 'active':
      statusColor = AppColors.getSuccess(isDark);
      statusLabel = 'Status: Active';
      break;
    case 'pending':
      statusColor = AppColors.getWarning(isDark);
      statusLabel = 'Status: Pending';
      break;
    case 'error':
      statusColor = AppColors.getError(isDark);
      statusLabel = 'Status: Error';
      break;
    default:
      statusColor = AppColors.getTextSecondary(isDark);
      statusLabel = 'Status: Unknown';
  }
  
  return Semantics(
    label: statusLabel,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
```

---

## 🎨 Theme Usage Examples

### Getting Theme Colors

```dart
// Get current theme brightness
final isDark = Theme.of(context).brightness == Brightness.dark;

// Get text colors
final primaryText = Theme.of(context).textTheme.bodyLarge?.color;
final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

// Get background colors
final bgColor = Theme.of(context).scaffoldBackgroundColor;
final surfaceColor = Theme.of(context).colorScheme.surface;
final cardColor = Theme.of(context).cardTheme.color;

// Get semantic colors
final primaryColor = Theme.of(context).colorScheme.primary;
final errorColor = Theme.of(context).colorScheme.error;

// Or use AppColors directly
final textColor = AppColors.getTextPrimary(isDark);
final successColor = AppColors.getSuccess(isDark);
final errorColor = AppColors.getError(isDark);
```

### Using Theme Text Styles

```dart
// Headings
Text('Large Heading', style: Theme.of(context).textTheme.displayLarge)
Text('Medium Heading', style: Theme.of(context).textTheme.displayMedium)
Text('Small Heading', style: Theme.of(context).textTheme.displaySmall)

// Titles
Text('Title', style: Theme.of(context).textTheme.titleLarge)
Text('Subtitle', style: Theme.of(context).textTheme.titleMedium)

// Body text
Text('Body text', style: Theme.of(context).textTheme.bodyLarge)
Text('Secondary text', style: Theme.of(context).textTheme.bodyMedium)
Text('Caption', style: Theme.of(context).textTheme.bodySmall)

// Labels
Text('Label', style: Theme.of(context).textTheme.labelLarge)
```

---

## 📳 Haptic Feedback Guide

### When to Use Each Type

```dart
// LIGHT - Minor interactions
HapticHelper.light()         // Small button taps
HapticHelper.navigation()    // Screen navigation
HapticHelper.toggle()        // Switch toggles
HapticHelper.dismiss()       // Dismiss dialogs

// MEDIUM - Standard interactions
HapticHelper.medium()        // Standard buttons
HapticHelper.buttonPress()   // Generic button press
HapticHelper.capture()       // Photo/file selection
HapticHelper.statusChange()  // Status updates
HapticHelper.notification()  // Notification actions

// HEAVY - Critical actions
HapticHelper.heavy()         // Important confirmations
HapticHelper.success()       // Successful submissions
HapticHelper.authentication() // Login/logout
HapticHelper.jobAccept()     // Dispatch acceptance
HapticHelper.delete()        // Destructive actions
HapticHelper.emergency()     // Emergency/SOS (double heavy)

// ERROR - Errors and warnings
HapticHelper.error()         // Generic error
HapticHelper.validationError() // Form validation errors

// SELECTION - Discrete values
HapticHelper.selection()     // Picker scrolling
```

---

## Testing Checklist for Each Screen

After implementing accessibility on a screen:

### Screen Reader Testing
- [ ] Enable VoiceOver (iOS) or TalkBack (Android)
- [ ] Navigate through entire screen
- [ ] Verify all buttons have labels
- [ ] Verify toggles announce state
- [ ] Verify images have descriptions
- [ ] Check navigation order is logical
- [ ] Test form field announcements

### Font Scaling Testing
- [ ] Set system font to Largest
- [ ] Navigate through screen
- [ ] Check for text overflow
- [ ] Verify buttons are still tappable
- [ ] Test with 200% scale if possible

### Haptic Testing
- [ ] Ensure device NOT in silent mode
- [ ] Test all button taps have haptics
- [ ] Verify toggle switches vibrate
- [ ] Check navigation has subtle haptic
- [ ] Confirm critical actions have strong haptic

### Dark Mode Testing
- [ ] Toggle dark mode in Settings
- [ ] Verify all text is readable
- [ ] Check all colors are themed
- [ ] Verify icons are visible
- [ ] Test images display properly

### Color Contrast Testing
- [ ] Use contrast checker tool
- [ ] Verify text ≥ 4.5:1 ratio
- [ ] Check button text ≥ 4.5:1
- [ ] Verify error messages ≥ 4.5:1

---

## 🚫 Common Mistakes to Avoid

### ❌ DON'T: Hard-code colors
```dart
Container(color: Colors.blue) // ❌ Won't change with dark mode
```

### DO: Use theme colors
```dart
Container(color: Theme.of(context).colorScheme.primary) // ✅
```

---

### ❌ DON'T: Hard-code text sizes
```dart
Text('Hello', style: TextStyle(fontSize: 16)) // ❌ Won't scale
```

### DO: Use theme styles
```dart
Text('Hello', style: Theme.of(context).textTheme.bodyLarge) // ✅
```

---

### ❌ DON'T: Forget Semantics on buttons
```dart
IconButton(icon: Icon(Icons.add), onPressed: () {}) // ❌ Screen reader can't describe
```

### DO: Add Semantics
```dart
Semantics(
  label: 'Add item',
  hint: 'Double tap to add',
  button: true,
  child: IconButton(icon: Icon(Icons.add), onPressed: () {}),
) // ✅
```

---

### ❌ DON'T: Forget haptic feedback
```dart
ElevatedButton(
  onPressed: () => performAction(), // ❌ No tactile feedback
  child: Text('Submit'),
)
```

### DO: Add haptic before action
```dart
ElevatedButton(
  onPressed: () async {
    await HapticHelper.buttonPress(); // ✅
    performAction();
  },
  child: Text('Submit'),
)
```

---

### ❌ DON'T: Use fixed-width containers for text
```dart
Container(
  width: 200,
  child: Text('Long text that might overflow...'), // ❌
)
```

### DO: Use flexible layouts
```dart
Flexible(
  child: Text('Long text that adapts to font size...'), // ✅
)
```

---

## 🎯 Priority Implementation Order

Apply these patterns to screens in this order:

1. **High Priority** (User-facing, frequent use)
   - Login/Sign-in screen
   - Dashboard screen
   - Dispatch list screen
   - Dispatch detail screen

2. **Medium Priority** (Important functionality)
   - Profile screen
   - Settings screen (already done ✅)
   - Report issue screen
   - Document upload screen

3. **Low Priority** (Infrequent use)
   - About screen
   - Help screen
   - Terms/Privacy screens

---

## 📚 Resources

- **Haptic Helper**: `lib/core/accessibility/haptic_helper.dart`
- **App Colors**: `lib/core/accessibility/app_colors.dart`
- **App Theme**: `lib/core/accessibility/app_theme.dart`
- **Example Screen**: This file (copy patterns from above)

---

**Questions?** See full documentation in `ACCESSIBILITY_UX_IMPLEMENTATION_SUMMARY.md`
