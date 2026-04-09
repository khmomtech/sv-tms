import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/about_app_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      //  provider.fetchAboutInfo(ApiConstants.baseUrl);
      Provider.of<AboutAppProvider>(context, listen: false).fetchAboutInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AboutAppProvider>(context);
    final isKhmer = context.locale.languageCode == 'km';

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final info = provider.aboutInfo;
    if (info == null) {
      return Scaffold(
        appBar: AppBar(title: Text('about.title'.tr())),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('about.error_failed'.tr()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.fetchAboutInfo(),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('about.title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.blue.shade100,
                    alignment: Alignment.center,
                    child: const Icon(Icons.local_shipping,
                        color: Colors.blue, size: 34),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isKhmer ? info.appNameKm : info.appNameEn,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              tr('about.android_version',
                  namedArgs: {'version': info.androidVersion}),
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              tr('about.ios_version', namedArgs: {'version': info.iosVersion}),
              style: const TextStyle(color: Colors.grey),
            ),
            if (provider.isUsingFallback) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'about.using_fallback'.tr(),
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => provider.fetchAboutInfo(),
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
              ),
            ],
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text('about.privacy_policy'.tr()),
              onTap: () => _launchUrl(
                isKhmer ? info.privacyPolicyUrlKm : info.privacyPolicyUrlEn,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text('about.terms_conditions'.tr()),
              onTap: () => _launchUrl(
                isKhmer ? info.termsConditionsUrlKm : info.termsConditionsUrlEn,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _launchUrl('mailto:${info.contactEmail}'),
              icon: const Icon(Icons.email_outlined),
              label: Text('about.contact_support'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
    }
  }
}
