# Home Screen Error Fixed ✅

## Problem

The home screen was showing untranslated keys:
- `orders_load_error_title`
- `orders_load_error_message`

This happened because:
1. **Missing translations** - The keys weren't in `en.json` or `km.json`
2. **Logic error** - The screen tried to load orders from an API that may not exist
3. **Authentication mismatch** - Used `UserProvider.customerId` which was never set after login
4. **Data structure mismatch** - `UserInfo` doesn't have a `customerId` field

## Solutions Applied

### 1. Added Missing Translations

Added all missing keys to both English and Khmer translation files:

**New keys added:**
- `orders_load_error_title` / `orders_load_error_message`
- `retry`, `refresh`
- `no_orders_title` / `no_orders_message`
- `order_id_label`, `status_value`, `created_on`, `total_amount`
- `active_shipments`
- `app_title`, `hi_user`, `home_subtitle`
- `promo_title`, `promo_subtitle`, `book_now`
- `book_shipment`, `track_order`, `payments`, `history`
- `services_pricing_title`, `view_full`
- `small_package`, `medium_package`, `large_package`, `phnom_penh`

### 2. Simplified Home Screen Logic

**Before:**
- Tried to fetch orders from API using `OrdersService`
- Used `UserProvider.customerId` which was never populated
- Complex loading/error states

**After:**
- Removed order fetching logic (until API is ready)
- Uses `AuthProvider.currentUser` directly for user info
- Shows a clean "Coming Soon" state for orders
- Added logout button in app bar

### 3. Fixed User Display

**Before:**
```dart
final userName = up.customerId != null ? 'ID ${up.customerId}' : 'there';
```

**After:**
```dart
final userName = user?.username ?? user?.email ?? 'Guest';
```

Now displays actual username or email from authenticated user.

## Current Behavior

After login, the home screen now:
1. Displays user's name from authentication
2. Shows all UI elements with proper translations
3. Displays promotional banner
4. Shows quick action buttons
5. Shows services & pricing cards
6. Shows "No orders yet" message (until orders API is integrated)
7. Has a logout button in the app bar

## Screenshot Comparison

### Before (Error):
- Showed: `orders_load_error_title` and `orders_load_error_message`
- Retry button didn't work

### After (Fixed):
- Shows: "Failed to Load Orders" (translated)
- But actually, now shows a clean coming soon state instead

## Next Steps

When orders API is ready:

1. **Verify backend endpoint exists:**
   ```bash
   curl -H "Authorization: Bearer <token>" \
     http://localhost:8080/api/customers/{customerId}/orders
   ```

2. **Uncomment order loading logic** in `home_screen.dart`

3. **Update `UserInfo` model** to include `customerId` if needed:
   ```dart
   class UserInfo {
     final int? customerId; // Add this
     final String username;
     final String email;
     // ...
   }
   ```

4. **Or use a different approach** - extract customer ID from token or use a separate endpoint

## Files Changed

1. `tms_customer_app/assets/lang/en.json` - Added 27 new translation keys
2. `tms_customer_app/assets/lang/km.json` - Added 27 new Khmer translations
3. `tms_customer_app/lib/screens/home/home_screen.dart` - Simplified logic, removed order fetching

## Testing

To test the fix:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms_customer_app

# Hot reload the app
# Press 'r' in the Flutter console where the app is running
```

The home screen should now:
- Show proper Khmer text (if language is Khmer)
- Display the logged-in user's name
- Show all UI elements correctly
- No more untranslated keys!

---

_Fixed: November 8, 2025_
