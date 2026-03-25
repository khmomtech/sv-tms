import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/providers/app_bootstrap_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/screens/shipment/profile/profile_vm.dart';
import 'package:tms_driver_app/screens/shipment/profile/sections/profile_header_section.dart';
import 'package:tms_driver_app/screens/shipment/profile/sections/profile_menu_section.dart';
import 'package:tms_driver_app/screens/shipment/profile/sections/profile_stats_section.dart';

class ProfileScreenModern extends StatefulWidget {
  const ProfileScreenModern({super.key});

  @override
  State<ProfileScreenModern> createState() => _ProfileScreenModernState();
}

class _ProfileScreenModernState extends State<ProfileScreenModern> {
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final isLoggedIn = await ApiConstants.isLoggedIn();
    if (!mounted) return;
    if (!isLoggedIn) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signin, (_) => false);
      return;
    }

    final provider = context.read<DriverProvider>();
    final apiHealth = <String, String>{};

    try {
      await provider.initializeDriverSession();
      apiHealth['driver.session'] = 'ok';
    } catch (e) {
      apiHealth['driver.session'] = 'failed: $e';
    }

    try {
      await provider.fetchDriverProfile();
      final status = provider.lastProfileFetchStatusCode;
      final error = provider.lastProfileFetchError;
      if (status != null && status >= 500) {
        apiHealth['driver.profile'] = 'failed: http $status (${error ?? 'server_error'})';
      } else if (status != null && status >= 400) {
        apiHealth['driver.profile'] = 'failed: http $status (${error ?? 'client_error'})';
      } else if (provider.driverProfile != null) {
        apiHealth['driver.profile'] = 'ok';
      } else {
        apiHealth['driver.profile'] = 'failed: ${error ?? 'empty profile payload'}';
      }
    } catch (e) {
      apiHealth['driver.profile'] = 'failed: $e';
    }

    try {
      await provider.fetchCurrentMonthPerformance();
      apiHealth['driver.performance'] = 'ok';
    } catch (e) {
      apiHealth['driver.performance'] = 'failed: $e';
    }

    try {
      await provider.fetchCurrentAssignment();
      apiHealth['driver.assignment'] = 'ok';
    } catch (e) {
      apiHealth['driver.assignment'] = 'failed: $e';
    }

    debugPrint('[Profile/API Health] $apiHealth');
  }

  Future<void> _refresh() => _loadProfile();

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('feature.coming_soon'))),
    );
  }

  Future<void> _shareDriverId(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('profile.id_copied'))),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 85);
    if (image == null || !mounted) return;

    setState(() => _isSavingProfile = true);
    try {
      await context
          .read<DriverProvider>()
          .uploadProfilePicture(File(image.path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('profile.save_success'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _showEditProfileDialog(Map<String, dynamic> profile) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(profile: profile),
    );

    if (!mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? context.tr('profile.save_success')
              : context.tr('profile.save_failed'),
        ),
      ),
    );
  }

  Future<void> _openEditActions(Map<String, dynamic> profile) async {
    if (!context
        .read<AppBootstrapProvider>()
        .isFeatureEnabled('edit_profile.enabled', fallback: true)) {
      _showComingSoon();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(context.tr('profile.edit_personal_info')),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Future<void>.delayed(const Duration(milliseconds: 140));
                if (!mounted) return;
                await _showEditProfileDialog(profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.tr('profile.change_photo_camera')),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.tr('profile.change_photo_gallery')),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, _) {
        final vm = ProfileVm.fromProvider(provider, context);
        final loading = provider.isLoading && provider.driverProfile == null;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF4F6FA),
            surfaceTintColor: const Color(0xFFF4F6FA),
            elevation: 0,
            leading: IconButton(
              icon:
                  Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              context.tr('profile.title'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert,
                    color: Theme.of(context).primaryColor),
                onPressed: _showComingSoon,
              ),
            ],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 30),
                    children: [
                      ProfileHeaderSection(
                        vm: vm,
                        onEditTap: () => _openEditActions(
                            provider.driverProfile ??
                                const <String, dynamic>{}),
                        onShareTap: () => _shareDriverId(vm.driverCode),
                      ),
                      ProfileStatsSection(vm: vm),
                      ProfileMenuSection(
                        titleKey: 'profile.documents',
                        items: [
                          ProfileMenuItemVm(
                            icon: Icons.badge_outlined,
                            titleKey: 'profile.documents_license',
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.myIdCard),
                          ),
                          ProfileMenuItemVm(
                            icon: Icons.medical_services_outlined,
                            titleKey: 'profile.documents_medical',
                            onTap: _showComingSoon,
                          ),
                          ProfileMenuItemVm(
                            icon: Icons.description_outlined,
                            titleKey: 'profile.documents_insurance',
                            onTap: _showComingSoon,
                          ),
                        ],
                      ),
                      ProfileMenuSection(
                        titleKey: 'profile.account_settings',
                        items: [
                          ProfileMenuItemVm(
                            icon: Icons.person_outline,
                            titleKey: 'profile.personal_information',
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settings),
                          ),
                          ProfileMenuItemVm(
                            icon: Icons.directions_car_outlined,
                            titleKey: 'profile.vehicle_details',
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.myVehicle),
                          ),
                          ProfileMenuItemVm(
                            icon: Icons.payments_outlined,
                            titleKey: 'profile.payment_settings',
                            onTap: _showComingSoon,
                          ),
                          ProfileMenuItemVm(
                            icon: Icons.settings_outlined,
                            titleKey: 'profile.app_settings',
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settings),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          floatingActionButton: _isSavingProfile
              ? const FloatingActionButton(
                  onPressed: null,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        );
      },
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstController;
  late final TextEditingController _lastController;
  late final TextEditingController _phoneController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _firstController = TextEditingController(
      text: (widget.profile['firstName'] ?? '').toString(),
    );
    _lastController = TextEditingController(
      text: (widget.profile['lastName'] ?? '').toString(),
    );
    _phoneController = TextEditingController(
      text: (widget.profile['phoneNumber'] ?? widget.profile['phone'] ?? '')
          .toString(),
    );
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final ok = await context.read<DriverProvider>().updateBasicProfile(
          firstName: _firstController.text,
          lastName: _lastController.text,
          phoneNumber: _phoneController.text,
        );
    if (!mounted) return;
    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('profile.edit_personal_info')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstController,
                decoration: InputDecoration(
                  labelText: context.tr('profile.first_name'),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr('profile.validation_required')
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastController,
                decoration: InputDecoration(
                  labelText: context.tr('profile.last_name'),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr('profile.validation_required')
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: context.tr('profile.phone_number'),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr('profile.validation_required')
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(context.tr('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _save,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('profile.save')),
        ),
      ],
    );
  }
}
