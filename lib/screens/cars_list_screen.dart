import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car_model.dart';
import '../models/trip_model.dart';
import '../providers/car_provider.dart';
import '../services/trip_dao.dart';
import 'car_edit_screen.dart';
import 'trips_list_screen.dart';

class CarsListScreen extends StatelessWidget {
  const CarsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои автомобили'),
        centerTitle: true,
      ),
      body: Consumer<CarProvider>(
        builder: (context, carProvider, child) {
          if (carProvider.cars.isEmpty) {
            return const Center(
              child: Text(
                'Нет добавленных автомобилей.\nНажмите "+" чтобы добавить.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: carProvider.cars.length,
            itemBuilder: (context, index) {
              final car = carProvider.cars[index];
              return _CarListTile(car: car);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Car? car) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CarEditScreen(car: car)),
    );
  }
}

class _CarListTile extends StatelessWidget {
  final Car car;

  const _CarListTile({required this.car});

  void _showCarSummary(BuildContext context) {
    final tripDao = TripDao();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Сводка: ${car.brand}'),
        content: FutureBuilder<List<Trip>>(
          future: tripDao.getTripsByCarId(car.id!),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('История рейсов пуста.');
            }
            
            final trips = snapshot.data!;
            final totalDistance = trips.fold(0, (sum, t) => sum + t.distance);
            final totalFuel = trips.fold(0.0, (sum, t) => sum + t.fuelConsumed);

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow('Госномер:', car.licensePlate),
                  _buildRow('Текущий пробег:', '${car.currentMileage} км'),
                  _buildRow('Топливо:', '${car.fuelInTank.toStringAsFixed(2)} / ${car.tankCapacity.toStringAsFixed(2)} л'),
                  _buildRow('Расход (профиль):', '${car.fuelConsumption.toStringAsFixed(2)} л/100км'),
                  const Divider(height: 24),
                  _buildRow('Всего рейсов:', '${trips.length}'),
                  _buildRow('Пробег по рейсам:', '$totalDistance км'),
                  _buildRow('Затрачено топлива:', '${totalFuel.toStringAsFixed(2)} л', isBold: true),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () => _showCarSummary(context),
        title: Text('${car.brand} (${car.licensePlate})'),
        // ИСПРАВЛЕНО: Разбиваем на две строки через \n для аккуратного отображения
        subtitle: Text('Пробег: ${car.currentMileage} км\nБак: ${car.fuelInTank.toStringAsFixed(2)} л'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.green),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TripsListScreen(car: car)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navigateToEdit(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CarEditScreen(car: car)),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить авто?'),
        content: Text('Удалить ${car.brand} (${car.licensePlate})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CarProvider>(context, listen: false).deleteCar(car.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}