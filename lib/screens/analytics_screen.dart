import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/refuel_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/optimization_settings_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/analytics_optimization_tab.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RefuelProvider>().loadRefuels();
      context.read<OptimizationProvider>().loadOptimizations();
      context.read<OptimizationSettingsProvider>().loadSettings();
      context.read<InventoryProvider>().loadInventories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика агрегатов'),
      ),
      body: const AnalyticsOptimizationTab(),
    );
  }
}