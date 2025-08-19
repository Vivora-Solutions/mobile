import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:book_my_salon/screens/auth/login_screen.dart';
// import 'package:book_my_salon/screens/home_screen.dart';
import 'package:book_my_salon/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:book_my_salon/screens/start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  AuthService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<AuthService>(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'Book My Salon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        ),
        home: const StartScreen(),
      ),
    );
  }
}
