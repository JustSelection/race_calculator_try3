import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car_model.dart';
import '../providers/car_provider.dart';
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
      MaterialPageRoute(
        builder: (context) => CarEditScreen(car: car),
      ),
    );
  }
}

class _CarListTile extends StatelessWidget {
  final Car car;
  const _CarListTile({required this.car});

    void _navigateToTrips(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripsListScreen(car: car),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text('${car.brand} (${car.licensePlate})'),
        subtitle: Text(
          'Пробег: ${car.currentMileage} км | Бак: ${car.fuelInTank} л',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.green),
              onPressed: () => _navigateToTrips(context),
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
      MaterialPageRoute(
        builder: (context) => CarEditScreen(car: car),
      ),
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
              Provider.of<CarProvider>(context, listen: false)
                  .deleteCar(car.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}