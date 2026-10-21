import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:globalpay/provider/balance_provider.dart';
import 'package:globalpay/provider/kyc_provider.dart';
import 'package:globalpay/provider/settings_provider.dart';
import 'package:globalpay/provider/subscription_provider.dart';
import 'package:globalpay/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'Market/cart_provider.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'splash_screen/splash_screen.dart';
import 'provider/authprovider.dart';
import 'provider/theme_provider.dart';
import 'registration_page/pin_login_page.dart';
import 'apps/apps.dart';

// Must be a top-level function (not inside a class) — runs in a separate isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run the two things the first frame needs IN PARALLEL instead of one
  // after the other. This shortens the time the native splash stays up.
  final results = await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ThemeProvider.load(),
  ]);
  final themeProvider = results[1] as ThemeProvider;

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider.value(value: UserBalance.instance),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // NOT awaited: the app draws first, push notifications set up in the
  // background. Previously this blocked the first frame.
  unawaited(
    PushNotificationService.initialize().catchError((e) {
      debugPrint('Push notification init failed: $e');
    }),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_tryAutoLogin);
  }

  Future<void> _tryAutoLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.tryAutoLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    // Theme is read outside the AuthProvider Consumer, so auth changes
    // don't interfere with theme toggles. toggle() also saves the choice
    // to the phone so it is remembered after the app is closed.
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    void toggleTheme() => context.read<ThemeProvider>().toggle();

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Glonest',
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Colors.deepOrange,
              secondary: Colors.deepOrange,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000),
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepOrange,
              secondary: Colors.deepOrange,
            ),
          ),
          home: auth.isCheckingAuth
              // Same white background + logo as the native splash while the
              // saved session is checked, so it looks like one continuous
              // splash.
              ? const _StartupScreen()
              : auth.needsPinUnlock
              ? PinLoginPage(
                  onToggleTheme: toggleTheme,
                  user: auth.pendingUser!,
                )
              : auth.isLoggedIn
              ? MyAppsPage(onToggleTheme: toggleTheme)
              : SplashScreen(onToggleTheme: toggleTheme),
        );
      },
    );
  }
}

/// Matches the native splash (white background + logo) so there is no
/// visible jump between the native splash and the first Flutter screen.
/// Background is forced white so dark mode can't cause a black flash.
class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/png/logo222.PNG',
          width: 150,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
