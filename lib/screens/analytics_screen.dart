import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/refuel_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/optimization_settings_provider.dart';
import '../widgets/analytics_optimization_tab.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadTrips(0);
      context.read<RefuelProvider>().loadRefuels();
      context.read<OptimizationProvider>().loadOptimizations();
      context.read<OptimizationSettingsProvider>().loadSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Автомобили'),
            Tab(text: 'Агрегаты и Оптимизация'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // 🆕 ИСПРАВЛЕНО: добавлен const перед списком, убраны const у элементов внутри
        children: const [
          _CarsTab(),
          AnalyticsOptimizationTab(),
        ],
      ),
    );
  }
}

class _CarsTab extends StatelessWidget {
  const _CarsTab();

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarProvider>().cars;
    
    if (cars.isEmpty) {
      return const Center(child: Text('Нет данных об автомобилях'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        final trips = context.watch<TripProvider>().trips.where((t) => t.carId == car.id).toList();
        
        final totalDistance = trips.fold(0, (sum, t) => sum + t.distance);
        final totalFuelConsumed = trips.fold(0.0, (sum, t) => sum + t.fuelConsumed);
        final avgConsumption = totalDistance > 0 ? (totalFuelConsumed / totalDistance * 100) : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${car.brand} (${car.licensePlate})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                _buildRow('Всего рейсов:', '${trips.length}'),
                _buildRow('Общий пробег:', '$totalDistance км'),
                _buildRow('Затрачено топлива:', '${totalFuelConsumed.toStringAsFixed(2)} л'),
                _buildRow('Средний расход:', '${avgConsumption.toStringAsFixed(2)} л/100км'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}