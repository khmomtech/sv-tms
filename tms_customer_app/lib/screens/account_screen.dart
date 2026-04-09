import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

/// Deprecated: Account screen consolidated into `ProfileScreen`.
/// This page redirects to the profile route to keep backwards compatibility
/// for any lingering references.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect immediately to profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
