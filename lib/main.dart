import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/location_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BagnoldSunCompassApp());
}

class BagnoldSunCompassApp extends StatelessWidget {
  const BagnoldSunCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bagnold Sun Compass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1208),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4A017),       // amber/gold
          secondary: Color(0xFFC8863A),     // burnt orange
          surface: Color(0xFF2A1F0E),       // dark brown
          onPrimary: Color(0xFF1A1208),
          onSecondary: Color(0xFF1A1208),
          onSurface: Color(0xFFE8D5A3),     // sand
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE8D5A3)),
          bodyMedium: TextStyle(color: Color(0xFFE8D5A3)),
          titleLarge: TextStyle(
            color: Color(0xFFD4A017),
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
          titleMedium: TextStyle(
            color: Color(0xFFD4A017),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A1F0E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF5C4520)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF5C4520)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD4A017), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB22222)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB22222), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9E7E3A)),
          hintStyle: const TextStyle(color: Color(0xFF5C4520)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4A017),
            foregroundColor: const Color(0xFF1A1208),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD4A017),
            side: const BorderSide(color: Color(0xFFD4A017)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1208),
          foregroundColor: Color(0xFFD4A017),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFD4A017),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
      home: const LocationScreen(),
    );
  }
}
