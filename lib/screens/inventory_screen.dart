import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_model.dart';
import '../models/generator_model.dart';
import '../providers/generator_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/car_provider.dart';
import '../widgets/inventory_car_selector.dart';
import '../widgets/inventory_generator_form.dart';

class InventoryScreen extends StatefulWidget {
  final int? preselectedGeneratorId;

  const InventoryScreen({super.key, this.preselectedGeneratorId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualFuelController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  int? _selectedCarId; 
  int? _selectedGeneratorId;

  @override
  void initState() {
    super.initState();
    
    if (widget.preselectedGeneratorId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        final generators = context.read<GeneratorProvider>().generators;
        
        GeneratorModel? gen;
        for (final g in generators) {
          if (g.id == widget.preselectedGeneratorId) {
            gen = g;
            break;
          }
        }
        
        // 🆕 ИСПРАВЛЕНО: Создаем локальную переменную safeGen внутри блока if.
        // Это позволяет Dart понять, что она не null внутри setState, 
        // не требуя оператора '!' и не вызывая ошибок.
        if (mounted && gen != null) {
          final safeGen = gen;
          setState(() {
            _selectedCarId = safeGen.carId ?? -1;
            _selectedGeneratorId = safeGen.id;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _actualFuelController.dispose();
    super.dispose();
  }

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  Future<void> _saveInventory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGeneratorId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите агрегат'), backgroundColor: Colors.red),
      );
      return;
    }

    final genProv = context.read<GeneratorProvider>();
    final invProv = context.read<InventoryProvider>();
    
    GeneratorModel? generator;
    for (final g in genProv.generators) {
      if (g.id == _selectedGeneratorId) {
        generator = g;
        break;
      }
    }
    
    if (generator == null || !mounted) return;

    final actualFuel = double.parse(_actualFuelController.text);
    final difference = _round(actualFuel - generator.currentFuel);

    final inventory = InventoryModel(
      generatorId: generator.id!,
      date: _selectedDate,
      previousFuel: generator.currentFuel,
      actualFuel: actualFuel,
      difference: difference,
    );

    final success = await invProv.addInventory(inventory);
    
    if (!mounted) return;

    if (success) {
      await genProv.loadGenerators();
      if (!mounted) return;
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Уровень обновлен. Расход зафиксирован.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final generators = context.watch<GeneratorProvider>().generators;
    final cars = context.watch<CarProvider>().cars;

    final List<GeneratorModel> filteredGenerators = _selectedCarId == null
        ? []
        : _selectedCarId == -1
            ? generators.where((g) => g.carId == null).toList()
            : generators.where((g) => g.carId == _selectedCarId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange),
            SizedBox(width: 8),
            Text('Работа агрегата'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Укажите текущий уровень. Он должен быть меньше или равен предыдущему, так как агрегат только расходует топливо.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              InventoryCarSelector(
                cars: cars,
                selectedCarId: _selectedCarId,
                onChanged: (value) {
                  setState(() {
                    _selectedCarId = value;
                    _selectedGeneratorId = null;
                    _actualFuelController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              InventoryGeneratorForm(
                filteredGenerators: filteredGenerators,
                selectedGeneratorId: _selectedGeneratorId,
                selectedDate: _selectedDate,
                actualFuelController: _actualFuelController,
                onGeneratorChanged: (value) {
                  setState(() {
                    _selectedGeneratorId = value;
                    _actualFuelController.clear();
                  });
                },
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                },
                onSave: _saveInventory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}