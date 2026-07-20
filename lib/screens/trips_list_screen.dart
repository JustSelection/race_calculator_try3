import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../models/trip_model.dart';
import '../providers/trip_provider.dart';
import '../providers/car_provider.dart';
import 'trip_details_screen.dart';

class TripsListScreen extends StatefulWidget {
  final Car car;
  const TripsListScreen({super.key, required this.car});

  @override
  State<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  @override
  void initState() {
    super.initState();
    // Загружаем рейсы при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).loadTrips(widget.car.id!);
    });
  }

  Future<void> _deleteTrip(Trip trip) async {
    final tripProv = Provider.of<TripProvider>(context, listen: false);
    final carProv = Provider.of<CarProvider>(context, listen: false);

    // 1. Удаляем рейс
    await tripProv.deleteTrip(trip.id!);

    // 2. Если удалили последний рейс, синхронизируем профиль авто
    final lastTrip = await tripProv.getLastTrip(widget.car.id!);
    if (lastTrip != null) {
      final updatedCar = widget.car.copyWith(
        currentMileage: lastTrip.endMileage,
        fuelInTank: lastTrip.remainingFuel,
      );
      await carProv.updateCar(updatedCar);
    } else {
      // Если рейсов больше нет, сбрасываем пробег и топливо к нулю
      final updatedCar = widget.car.copyWith(
        currentMileage: 0,
        fuelInTank: 0.0,
      );
      await carProv.updateCar(updatedCar);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Рейс удален')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Рейсы: ${widget.car.licensePlate}'),
      ),
      body: Consumer<TripProvider>(
        builder: (ctx, tripProv, _) {
          if (tripProv.trips.isEmpty) {
            return const Center(
              child: Text('История рейсов пуста', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }
          return ListView.builder(
            itemCount: tripProv.trips.length,
            itemBuilder: (ctx, index) {
              final trip = tripProv.trips[index];
              return _TripListTile(
                trip: trip,
                car: widget.car,
                onDelete: () => _deleteTrip(trip),
              );
            },
          );
        },
      ),
    );
  }
}

class _TripListTile extends StatelessWidget {
  final Trip trip;
  final Car car;
  final VoidCallback onDelete;

  const _TripListTile({required this.trip, required this.car, required this.onDelete});

  void _showTripSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сводка по рейсу'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Дата:', DateFormat('dd.MM.yyyy').format(trip.date)),
              _buildRow('Нач. пробег:', '${trip.startMileage} км'),
              _buildRow('Кон. пробег:', '${trip.endMileage} км'),
              _buildRow('Дистанция:', '${trip.distance} км'),
              const Divider(height: 24),
              _buildRow('Топливо на выезде:', '${trip.fuelAtDeparture.toStringAsFixed(2)} л'),
              _buildRow('Заправлено:', '${trip.refueled.toStringAsFixed(2)} л'),
              _buildRow('Затрачено:', '${trip.fuelConsumed.toStringAsFixed(2)} л'),
              _buildRow('Остаток:', '${trip.remainingFuel.toStringAsFixed(2)} л', isBold: true),
            ],
          ),
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
        onTap: () => _showTripSummary(context), // <-- ДОБАВЛЕНО: вызов сводки при нажатии на карточку
        title: Text(DateFormat('dd.MM.yyyy').format(trip.date)),
        subtitle: Text(
          'Дистанция: ${trip.distance} км | Остаток: ${trip.remainingFuel.toStringAsFixed(2)} л',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => TripDetailsScreen(trip: trip, car: car),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}