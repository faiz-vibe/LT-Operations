import 'services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/box_item.dart';
import 'models/vehicle_entry.dart';
import 'screens/home_screen.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive Database Initialize karna
  await Hive.initFlutter();

  // Adapters Register karna
  Hive.registerAdapter(VehicleEntryAdapter());
  Hive.registerAdapter(BoxItemAdapter());

  // Safe Box Opening
  try {
    await Hive.openBox<VehicleEntry>('vehicle_entries');
  } catch (e) {
    await Hive.deleteBoxFromDisk('vehicle_entries');
    await Hive.openBox<VehicleEntry>('vehicle_entries');
  }

  await Hive.openBox<String>('vehicles');
  await Hive.openBox<String>('drivers');
  await Hive.openBox<String>('driver_mobiles');
  await Hive.openBox<String>('companies');
  await Hive.openBox<String>('damage_details');
  await Hive.openBox<String>('locations');
  await Hive.openBox<String>('archive_box'); // Archive Box
  await Hive.openBox<String>('zone_mapping'); // Zone mapping ke liye naya box

  await PreferencesService.init();
  runApp(const TransportSupervisorApp());
}

class TransportSupervisorApp extends StatelessWidget {
  const TransportSupervisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: PreferencesService.themeMode,
      builder: (context, themeMode, child) {
        final isDark = themeMode == AppThemeMode.dark;
        return MaterialApp(
          title: 'LT Operations',
          debugShowCheckedModeBanner: false,
          theme: isDark ? _buildDarkTheme() : _buildLightTheme(),
          home: child,
        );
      },
      child: const HomeScreen(),
    );
  }

  // DARK THEME
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD84315),
        primary: const Color(0xFFFF7043),
        secondary: const Color(0xFFFF8F00),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF3E3E3E), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7043),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // LIGHT THEME
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD84315),
        primary: const Color(0xFFD84315),
        secondary: const Color(0xFFFF8F00),
        surface: const Color(0xFFF5F6FA),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD84315),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        margin: EdgeInsets.zero,
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFD84315), width: 2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD84315),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 1,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD84315)),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
    );
  }
}