import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/generator_model.dart';
import '../models/refuel_model.dart';
import '../providers/car_provider.dart';
import '../providers/generator_provider.dart';
import '../providers/refuel_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/inventory_provider.dart'; // 🆕 Добавлено
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
  bool _isInitialized = false;
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

  void _initControllers(List<GeneratorModel> generators) {
    if (_isInitialized) return;
    for (final gen in generators) {
      if (!_controllers.containsKey(gen.id)) {
        _controllers[gen.id!] = TextEditingController(text: gen.currentFuel.toString())
          ..addListener(_updateSum);
      }
    }
    _updateSum();
    _isInitialized = true;
  }

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  Future<void> _saveRefuel() async {
    if (!_formKey.currentState!.validate()) return;
    
    final generators = context.read<GeneratorProvider>().generators;
    final Map<int, double> newLevels = {};
    
    for (final gen in generators) {
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
      final invProv = context.read<InventoryProvider>(); // 🆕 Получаем провайдер инвентаризации
      
      await genProv.loadGenerators();
      await optProv.loadAnalytics();
      await invProv.loadInventories(); // 🆕 ПРИНУДИТЕЛЬНО обновляем список инвентаризаций

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
    
    _initControllers(generators);

    final filteredGens = _selectedCarId == null || _selectedCarId == -1
        ? (_selectedCarId == -1 ? generators.where((g) => g.carId == null).toList() : generators)
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
            Expanded(
              child: RefuelDistributionList(
                allGenerators: generators,
                cars: cars,
                selectedCarId: _selectedCarId,
                controllers: _controllers,
                onCarFilterChanged: (value) => setState(() => _selectedCarId = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveRefuel,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Сохранить фактические уровни'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}