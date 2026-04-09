App Store Privacy — Suggested answers (copy/paste into App Store Connect)

Notes
- Person who must complete this: an Admin role in App Store Connect.
- This file provides suggested answers and short instructions for the App Privacy questionnaire.
- Review and adapt answers to your exact data collection/retention policies before submitting.

Contact / metadata
- App owner / contact:
  - Name: Sothea Khet
  - Email: khetsothea@gmail.com
  - Phone: +85516264343

Where to go
1. Sign in to App Store Connect (Admin role).
2. My Apps → select your app → App Privacy (left side) → Edit App Privacy.
3. For each section, use the guidance below to select data types, purposes, and whether data is collected & linked to user.

Third-party SDKs used (report these in the "Does your app integrate third-party SDKs?" step):
- Firebase (Analytics, Cloud Messaging, Crashlytics) — analytics, push token, crash logs
- Sentry — crash diagnostics
- Google Maps / Places — mapping and routing (if included)
- Geolocator / location plugin — precise device location
- Others: `flutter_secure_storage`, `dio` (network), `cached_network_image` (images)

Suggested answers (one-line values to paste where App Store asks)
1) Does the app collect any data from the user? — Yes
2) Does the app collect data from the device? — Yes
3) Does the app collect data linked to the user’s identity? — Yes (some categories)

Data categories and suggested selection (mark "Yes/No" and whether "Collected" and whether "Linked to User")
- Identifiers (device ID, user ID, advertising ID)
  - Collected: Yes
  - Linked to User: Yes
  - Purpose: Account, authentication, push messaging, fraud prevention
- Contact Info (email)
  - Collected: Yes
  - Linked to User: Yes
  - Purpose: Account, password recovery, notifications, support
- Location (Precise Location)
  - Collected: Yes
  - Linked to User: Yes
  - Purpose: Dispatch, routing, location tracking while on duty
- User Content (Photos / Camera / Media)
  - Collected: Yes
  - Linked to User: Yes
  - Purpose: Proof of delivery (photo uploads)
- Usage Data (Analytics)
  - Collected: Yes
  - Linked to User: No (aggregate / pseudonymous analytics) — *note:* if you link analytics to login, mark Yes
  - Purpose: App performance and usage analytics
- Diagnostics (Crash logs)
  - Collected: Yes
  - Linked to User: No (unless crash logs include user identifiers) — Sentry may include optional identifiers
  - Purpose: Crash reporting and bug fixes
- Sensitive Data (Health, Financial, Contacts) —
  - Collected: No (unless your app explicitly uses contacts/health/payment features)

Tracking & Advertising
- Uses Tracking: No (the driver app does not show ads or perform cross-app ad tracking). If you use IDFA or serve ads, mark Yes and explain.

Data linked to the user? (summary)
- A subset of data is linked to the user (identifiers, contact info, location, user content). Analytics and diagnostics are typically not linked, unless explicitly configured.

Data retention & deletion
- Suggested statement (paste into fields where App Store asks):
  "Data is retained as required to provide service and for troubleshooting. User content (proof-of-delivery images) and account records are retained for business purposes and legal compliance; typical retention windows are up to 3 years unless the user requests deletion. Contact khetsothea@gmail.com for deletion requests."
  (Adjust retention period to match your backend policy.)

Privacy policy URL
- Make sure your app listing includes a valid Privacy Policy URL. If you have one in backend or docs, paste it into App Store Connect.
- If you don't have a hosted policy, create a simple privacy page (example: https://svtms.svtrucking.biz/privacy) and add it to the repo / website.

Export & testing
- After filling the App Privacy form, save and continue.
- The Admin must submit the app for review after the privacy form is completed.

What to paste in App Store Connect App Privacy fields
- Use the per-category answers above. For any ambiguous category, err on the side of transparency (mark "Collected" and describe purpose). 

Follow-ups I can do for you
- Generate a short hosted Privacy Policy (Markdown -> HTML) and a simple privacy page if you want me to create one here and commit it to the repo.
- If you'd like, I can prepare the exact checkbox selections in a compact table to paste into App Store Connect or I can walk an Admin through each App Store Connect screen live.

---
Review this file and confirm any specific retention/window values and whether analytics/diagnostics are linked to your user IDs — I'll update the file accordingly and can commit the finalized version.
