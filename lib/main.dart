import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/box_item.dart';
import 'models/vehicle_entry.dart';
import 'screens/home_screen.dart'; // Yeh add karein


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive Database Initialize karna
  await Hive.initFlutter();

  // Adapters Register karna
  Hive.registerAdapter(VehicleEntryAdapter());
  Hive.registerAdapter(BoxItemAdapter());

  // Safe Box Opening: Agar purane data me error aaye toh use delete karke naya khol lein
  try {
    await Hive.openBox<VehicleEntry>('vehicle_entries');
  } catch (e) {
    await Hive.deleteBoxFromDisk('vehicle_entries');
    await Hive.openBox<VehicleEntry>('vehicle_entries');
  }

  // Company names save karne ke liye naya box
  await Hive.openBox<String>('vehicles');
  await Hive.openBox<String>('drivers');
  await Hive.openBox<String>('driver_mobiles');
  await Hive.openBox<String>('companies');
  await Hive.openBox<String>('damage_details');
  await Hive.openBox<String>('locations');

  runApp(const TransportSupervisorApp());
}

class TransportSupervisorApp extends StatelessWidget {
  const TransportSupervisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LT Operations',
      debugShowCheckedModeBanner: false,
      // PRO THEME: Modern Material 3 setup with Let's Transport Orange
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100), // Deep Orange (Brand Color)
          primary: const Color(0xFFE65100),
          secondary: const Color(0xFFFF8F00), // Amber for accents
          surface: const Color(0xFFFFF8F1),   // Warm Light background
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F1), // Very light warm white
        fontFamily: 'Roboto', // Or your preferred font

        // AppBar ko clean aur modern banaya with Brand Color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE65100), // Deep Orange
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),

        // Cards ke liye soft shadows aur rounded corners
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          margin: EdgeInsets.zero,
          color: Colors.white,
        ),

        // Saare TextFields ko ekdum premium aur rounded banaya
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFE65100), width: 2), // Focus orange
          ),
        ),

        // Buttons ko modern aur rounded banaya with Brand Color
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE65100), // Deep Orange
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            elevation: 2,
          ),
        ),

        // Text styles for better readability
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}