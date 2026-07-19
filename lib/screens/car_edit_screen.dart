import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car_model.dart';
import '../providers/car_provider.dart';

class CarEditScreen extends StatefulWidget {
  final Car? car;
  const CarEditScreen({super.key, this.car});

  @override
  State<CarEditScreen> createState() => _CarEditScreenState();
}

class _CarEditScreenState extends State<CarEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _brandController;
  late TextEditingController _plateController;
  late TextEditingController _consumptionController;
  late TextEditingController _mileageController;
  late TextEditingController _fuelController;
  late TextEditingController _tankController;

  bool get isEditing => widget.car != null;

  @override
  void initState() {
    super.initState();
    final car = widget.car;
    _brandController = TextEditingController(text: car?.brand ?? '');
    _plateController = TextEditingController(text: car?.licensePlate ?? '');
    _consumptionController = TextEditingController(text: car?.fuelConsumption.toStringAsFixed(2) ?? '');
    _mileageController = TextEditingController(text: car?.currentMileage.toString() ?? '');
    _fuelController = TextEditingController(text: car?.fuelInTank.toStringAsFixed(2) ?? '');
    _tankController = TextEditingController(text: car?.tankCapacity.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _brandController.dispose();
    _plateController.dispose();
    _consumptionController.dispose();
    _mileageController.dispose();
    _fuelController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final brand = _brandController.text.trim();
    final plate = _plateController.text.trim();
    final consumption = double.parse(_consumptionController.text.trim());
    final mileage = int.parse(_mileageController.text.trim());
    final fuel = double.parse(_fuelController.text.trim());
    final tank = double.parse(_tankController.text.trim());

    final carProvider = Provider.of<CarProvider>(context, listen: false);

    if (isEditing) {
      final updatedCar = widget.car!.copyWith(
        brand: brand,
        licensePlate: plate,
        fuelConsumption: consumption,
        currentMileage: mileage,
        fuelInTank: fuel,
        tankCapacity: tank,
      );
      carProvider.updateCar(updatedCar);
    } else {
      final newCar = Car(
        brand: brand,
        licensePlate: plate,
        fuelConsumption: consumption,
        currentMileage: mileage,
        fuelInTank: fuel,
        tankCapacity: tank,
      );
      carProvider.addCar(newCar);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактирование авто' : 'Новое авто'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_brandController, 'Марка', false),
              _buildTextField(_plateController, 'Госномер', false),
              _buildTextField(_consumptionController, 'Расход (л/100км)', false, isDecimal: true),
              _buildTextField(_mileageController, 'Текущий пробег (км)', false, isInteger: true),
              _buildTextField(_fuelController, 'Топливо в баке (л)', false, isDecimal: true),
              _buildTextField(_tankController, 'Объем бака (л)', false, isDecimal: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool isOptional, {
    bool isDecimal = false,
    bool isInteger = false,
  }) {
    // Определяем тип клавиатуры
    TextInputType keyType = TextInputType.text;
    if (isDecimal) {
      keyType = const TextInputType.numberWithOptions(decimal: true);
    } else if (isInteger) {
      keyType = TextInputType.number;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return isOptional ? null : 'Поле обязательно';
          }
          if (isDecimal && double.tryParse(value.trim()) == null) {
            return 'Введите число';
          }
          if (isInteger && int.tryParse(value.trim()) == null) {
            return 'Введите целое число';
          }
          return null;
        },
      ),
    );
  }
}