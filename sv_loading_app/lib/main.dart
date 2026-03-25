import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'core/api/api_client.dart';
import 'core/auth/token_store.dart';
import 'state/auth_provider.dart';
import 'state/connectivity_provider.dart';
import 'state/g_management_context_provider.dart';
import 'state/g_management_provider.dart';
import 'state/loading_provider.dart';
import 'state/trip_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

String _resolveApiBaseUrl() {
  const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (fromDefine.trim().isNotEmpty) {
    return fromDefine.trim();
  }

  if (kIsWeb) {
    return 'http://localhost:8080';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    // Android emulator -> host machine localhost
    return 'http://10.0.2.2:8080';
  }

  // iOS simulator / macOS / others
  return 'http://localhost:8080';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final baseUrl = _resolveApiBaseUrl();
  debugPrint('SV Loading API base URL: $baseUrl');
  final api = await ApiClient.create(baseUrl);

  final token = await TokenStore().getToken();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('km')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => ConnectivityProvider()..start()),
          Provider.value(value: api),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
          ChangeNotifierProvider(create: (_) => TripProvider(api)),
          ChangeNotifierProvider(create: (_) => LoadingProvider(api)),
          ChangeNotifierProvider(create: (_) => GManagementContextProvider()),
          ChangeNotifierProvider(
            create: (ctx) => GManagementProvider(
              api,
              ctx.read<GManagementContextProvider>(),
            ),
          ),
        ],
        child: MyApp(startLoggedIn: token != null && token.isNotEmpty),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool startLoggedIn;
  const MyApp({super.key, required this.startLoggedIn});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B63CE),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'SV Loading - Team G',
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F2937),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      home: startLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
