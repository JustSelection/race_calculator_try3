import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/generator_model.dart';
import '../models/refuel_model.dart';
import '../providers/car_provider.dart';
import '../providers/generator_provider.dart';
import '../providers/refuel_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/analytics_event_provider.dart';
import '../widgets/refuel_distribution_header.dart';
import '../widgets/refuel_distribution_list.dart';

class RefuelDistributionScreen extends StatefulWidget {
  final double totalFuel;
  final DateTime date;
  final String comment;

  const RefuelDistributionScreen({
    super.key,
    required this.totalFuel,
    required this.date,
    required this.comment,
  });

  @override
  State<RefuelDistributionScreen> createState() => _RefuelDistributionScreenState();
}

class _RefuelDistributionScreenState extends State<RefuelDistributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  double _newTotalSum = 0.0;
  int? _selectedCarId;

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _updateSum() {
    double sum = 0.0;
    for (final ctrl in _controllers.values) {
      sum += (double.tryParse(ctrl.text) ?? 0.0);
    }
    setState(() => _newTotalSum = double.parse(sum.toStringAsFixed(2)));
  }

  void _initControllersForCar(List<GeneratorModel> allGenerators, int? carId) {
    _controllers.clear();
    if (carId != null) {
      final carGens = allGenerators.where((g) => g.carId == carId).toList();
      for (final gen in carGens) {
        _controllers[gen.id!] = TextEditingController(text: gen.currentFuel.toString())
          ..addListener(_updateSum);
      }
    }
    _updateSum();
  }

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  Future<void> _saveRefuel() async {
    if (!_formKey.currentState!.validate()) return;
    
    final generators = context.read<GeneratorProvider>().generators;
    final Map<int, double> newLevels = {};
    
    final carGens = generators.where((g) => g.carId == _selectedCarId).toList();
    for (final gen in carGens) {
      final ctrl = _controllers[gen.id];
      if (ctrl != null && ctrl.text.isNotEmpty) {
        newLevels[gen.id!] = double.parse(ctrl.text);
      }
    }
    
    final refuel = RefuelModel(
      date: widget.date, 
      totalFuel: widget.totalFuel, 
      comment: widget.comment.isEmpty ? null : widget.comment
    );
    
    final success = await context.read<RefuelProvider>().addRefuel(refuel, newLevels);
    
    if (!mounted) return;
    
    if (success) {
      final genProv = context.read<GeneratorProvider>();
      final optProv = context.read<OptimizationProvider>();
      final invProv = context.read<InventoryProvider>();
      final eventProv = context.read<AnalyticsEventProvider>();
      
      await genProv.loadGenerators();
      await optProv.loadAnalytics();
      await invProv.loadInventories();
      await eventProv.loadEvents();

      if (!mounted) return;

      Navigator.pop(context); 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заправка и фактические уровни сохранены')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final generators = context.watch<GeneratorProvider>().generators;
    final cars = context.watch<CarProvider>().cars;

    final filteredGens = _selectedCarId == null 
        ? <GeneratorModel>[] 
        : generators.where((g) => g.carId == _selectedCarId).toList();

    final oldTotal = _round(filteredGens.fold(0.0, (sum, g) => sum + g.currentFuel));
    final expectedTotal = _round(oldTotal + widget.totalFuel);

    return Scaffold(
      appBar: AppBar(title: const Text('Фактические уровни (Шаг 2/2)')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            RefuelDistributionHeader(
              totalFuel: widget.totalFuel, 
              oldTotal: oldTotal, 
              expectedTotal: expectedTotal, 
              newTotalSum: _newTotalSum
            ),
            
            if (_selectedCarId != null && filteredGens.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'К этому автомобилю не привязано агрегатов. Весь объем заправки (${widget.totalFuel} л) будет учтен как расход (работа агрегатов).',
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: RefuelDistributionList(
                allGenerators: generators,
                cars: cars,
                selectedCarId: _selectedCarId,
                controllers: _controllers,
                onCarFilterChanged: (value) {
                  _initControllersForCar(generators, value);
                  setState(() => _selectedCarId = value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedCarId == null ? null : _saveRefuel,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    // 🆕 ИЗМЕНЕНО: Явно задаем яркий синий цвет для активной кнопки
                    backgroundColor: _selectedCarId == null ? Colors.grey.shade300 : Colors.blue,
                    foregroundColor: _selectedCarId == null ? Colors.grey.shade600 : Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                  ),
                  child: Text(
                    _selectedCarId == null ? 'Сначала выберите автомобиль' : 'Сохранить фактические уровни',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // 🆕 Жирный шрифт для заметности
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}