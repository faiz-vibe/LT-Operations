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
  await Hive.openBox<String>('driver_mobiles'); // Naya box
  await Hive.openBox<String>('companies');
  await Hive.openBox<String>('damage_details');

  runApp(const TransportSupervisorApp());
}

class TransportSupervisorApp extends StatelessWidget {
  const TransportSupervisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transport Supervisor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Yahan HomeScreen set kiya hai
    );
  }
}