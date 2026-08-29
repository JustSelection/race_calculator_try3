import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_helper.dart';
import 'providers/car_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/calculator_provider.dart';
import 'providers/generator_provider.dart';
import 'providers/optimization_provider.dart';
import 'providers/optimization_settings_provider.dart';
import 'providers/refuel_provider.dart'; // 🆕 ДОБАВЛЕНО
import 'providers/inventory_provider.dart'; // 🆕 ДОБАВЛЕНО
import 'providers/calibration_provider.dart'; // 🆕 ДОБАВЛЕНО
import 'providers/analytics_event_provider.dart'; // 🆕 ДОБАВЛЕНО
import 'screens/calculator_screen.dart';
import 'screens/cars_list_screen.dart';
import 'screens/generators_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarProvider()..loadCars()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        ChangeNotifierProvider(create: (_) => GeneratorProvider()..loadGenerators()),
        ChangeNotifierProvider(create: (_) => OptimizationProvider()),
        ChangeNotifierProvider(create: (_) => OptimizationSettingsProvider()..loadSettings()),
        // 🆕 Новые провайдеры для расширенного функционала
        ChangeNotifierProvider(create: (_) => RefuelProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CalibrationProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsEventProvider()),
      ],
      child: MaterialApp(
        title: 'Калькулятор пробега',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final _screens = const [
    CalculatorScreen(),
    CarsListScreen(),
    GeneratorsListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Калькулятор',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Автомобили',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Агрегаты',
          ),
        ],
      ),
    );
  }
}