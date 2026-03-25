import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/pending_queue_service.dart';
import 'services/safety_service.dart';
import 'services/stats_service.dart';

class SvtmsSafetyApp extends StatefulWidget {
  const SvtmsSafetyApp({super.key});

  @override
  State<SvtmsSafetyApp> createState() => _SvtmsSafetyAppState();
}

class _SvtmsSafetyAppState extends State<SvtmsSafetyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<AuthService>()),
        ),
        ChangeNotifierProvider<StatsService>(
          create: (_) => StatsService(),
        ),
        ProxyProvider<AuthService, ApiClient>(
          update: (_, auth, __) => ApiClient(auth),
        ),
        ProxyProvider<ApiClient, SafetyService>(
          update: (_, api, __) => SafetyService(api),
        ),
        ChangeNotifierProvider<PendingQueueService>(
          create: (_) => PendingQueueService(),
        ),
      ],
      child: const _BootstrapGate(),
    );
  }
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate();

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  late Future<void> _bootFuture;

  @override
  void initState() {
    super.initState();
    _bootFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pendingQueue =
        Provider.of<PendingQueueService>(context, listen: false);
    final stats = Provider.of<StatsService>(context, listen: false);
    await authProvider.init();
    await pendingQueue.init();
    await stats.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Loading...")
                  ],
                ),
              ),
            ),
          );
        }

        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final needsPin = auth.loggedIn && auth.pinSet && !auth.pinVerified;
            return MaterialApp(
              title: 'SVTMS Safety',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme:
                    ColorScheme.fromSeed(seedColor: Colors.green.shade700),
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  iconTheme: const IconThemeData(color: Colors.white),
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                useMaterial3: true,
              ),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: auth.loggedIn
                  ? (needsPin ? const PinLockScreen() : const HomeScreen())
                  : const LoginScreen(),
            );
          },
        );
      },
    );
  }
}
