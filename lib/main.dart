import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const IPSCTrackerApp());
}

class IPSCTrackerApp extends StatelessWidget {
  const IPSCTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3GS Training',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppTheme.accentBlue,
        scaffoldBackgroundColor: AppTheme.primaryDark,
        fontFamily: 'System',
        
        // Color scheme
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accentBlue,
          secondary: AppTheme.accentGreen,
          surface: AppTheme.cardBg,
          background: AppTheme.primaryDark,
          error: AppTheme.accentRed,
        ),
        
        // Card theme
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: AppTheme.heading2,
        ),
        
        // Text theme
        textTheme: const TextTheme(
          displayLarge: AppTheme.heading1,
          displayMedium: AppTheme.heading2,
          displaySmall: AppTheme.heading3,
          bodyLarge: AppTheme.bodyLarge,
          bodyMedium: AppTheme.bodyMedium,
          bodySmall: AppTheme.bodySmall,
          labelLarge: AppTheme.label,
        ),
        
        // Floating Action Button
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppTheme.accentGreen,
          foregroundColor: Colors.white, // Weiß statt schwarz
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
        
        // Elevated Button Theme - WICHTIG für lesbare Button-Texte überall
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Weiß für alle Buttons
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}