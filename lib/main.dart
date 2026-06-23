import 'package:flutter/material.dart';
import 'package:globalpay/provider/kyc_provider.dart';
import 'package:globalpay/provider/settings_provider.dart';
import 'package:globalpay/provider/subscription_provider.dart';
import 'package:globalpay/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'Market/cart_provider.dart';
import 'splash_screen/splash_screen.dart';
import 'provider/authprovider.dart';
import 'apps/apps.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()), // ← here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_tryAutoLogin);
  }

  Future<void> _tryAutoLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.tryAutoLogin(context); // ← pass context
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
              : auth.isLoggedIn
              ? MyAppsPage(onToggleTheme: toggleTheme)
              : SplashScreen(onToggleTheme: toggleTheme),
        );
      },
    );
  }
}
