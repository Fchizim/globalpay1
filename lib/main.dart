import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'splash_screen/splash_screen.dart';
=======
import 'package:provider/provider.dart';
import 'splash_screen/splash_screen.dart';
import 'provider/authprovider.dart';
import 'home/home_page.dart';
import 'apps/apps.dart';
>>>>>>> c30d5f6 (initial commit)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  // 🟢 Launch the app directly (no Firebase anymore)
  runApp(const MyApp());
=======
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
>>>>>>> c30d5f6 (initial commit)
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
<<<<<<< HEAD
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GlobalPay',

      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // 🌞 Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.deepOrange,
          secondary: Colors.deepOrange,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),

      // 🌙 Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrange,
          secondary: Colors.deepOrange,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),

      // 🏁 Start from SplashScreen
      home: SplashScreen(onToggleTheme: toggleTheme),
    );
  }
}
=======
  void initState() {
    super.initState();
    Future.microtask(_tryAutoLogin);
  }

  Future<void> _tryAutoLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GlobalPay',
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // 🌞 Light theme
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Colors.deepOrange,
              secondary: Colors.deepOrange,
            ),
          ),

          // 🌙 Dark theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000),
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepOrange,
              secondary: Colors.deepOrange,
            ),
          ),

          // 🏁 Start screen (SAFE)
          home: auth.isCheckingAuth
              ? const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          )
              : auth.isLoggedIn
              ? MyAppsPage(onToggleTheme: toggleTheme)
              : SplashScreen(onToggleTheme: toggleTheme),
        );
      },
    );
  }
}
>>>>>>> c30d5f6 (initial commit)
