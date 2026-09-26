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
  print('🚀 [0] WidgetsFlutterBinding ready');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🚀 [0.5] Firebase.initializeApp done');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await PushNotificationService.initialize();
  print('🚀 [A] About to call runApp()');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider.value(value: UserBalance.instance),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()), // ← here
      ],
      child: const MyApp(),
    ),
  );
  print('🚀 [B] runApp() returned');
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
    print('🟢 [C] MyApp initState called');
    Future.microtask(_tryAutoLogin);
  }

  Future<void> _tryAutoLogin() async {
    print('🟢 [D] _tryAutoLogin started');
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.tryAutoLogin(context); // ← pass context
    print('🟢 [E] _tryAutoLogin finished');
  }

  @override
  Widget build(BuildContext context) {
    print('🟡 [F] MyApp build() called');

    // Read theme here, OUTSIDE the AuthProvider Consumer below. This is
    // the key change: theme state no longer lives inside this State
    // object, and MaterialApp's themeMode now comes from watching
    // ThemeProvider directly. An AuthProvider notification only reruns
    // the Consumer's builder (still needed for isCheckingAuth /
    // needsPinUnlock / isLoggedIn routing) — it no longer also rebuilds
    // MaterialApp for theme reasons, and a theme toggle no longer needs
    // to touch AuthProvider at all. That removes the rebuild collision
    // that could previously swallow a tap on the dark-mode switch.
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    void toggleTheme() => context.read<ThemeProvider>().toggle();

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        print(
          '🟡 [G] Consumer builder called, isCheckingAuth=${auth.isCheckingAuth}, '
          'needsPinUnlock=${auth.needsPinUnlock}, isLoggedIn=${auth.isLoggedIn}',
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GlobalPay',
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
          // ← NO builder here
          home: auth.isCheckingAuth
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : auth.needsPinUnlock
              // Saved session found but not yet PIN-verified this launch —
              // this is the PalmPay-style unlock step, shown before the
              // person ever reaches the authenticated app shell.
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
