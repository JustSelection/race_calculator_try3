import 'package:flutter/material.dart';
import '../models/generator_model.dart';

class CalibrationGeneratorList extends StatelessWidget {
  final List<GeneratorModel> generators;
  final Map<int, TextEditingController> controllers;

  const CalibrationGeneratorList({
    super.key,
    required this.generators,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: generators.length,
        itemBuilder: (context, index) {
          final gen = generators[index];
          
          // Инициализируем контроллер, если его еще нет
          if (!controllers.containsKey(gen.id)) {
            controllers[gen.id!] = TextEditingController(text: gen.currentFuel.toString());
          }
          final ctrl = controllers[gen.id!]!;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(gen.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Текущий в системе: ${gen.currentFuel} л'),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Новый остаток (л)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}