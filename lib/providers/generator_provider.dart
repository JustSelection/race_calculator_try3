import 'package:flutter/foundation.dart';
import '../models/generator_model.dart';
import '../services/generator_dao.dart';

class GeneratorProvider extends ChangeNotifier {
  final GeneratorDao _dao = GeneratorDao();
  List<GeneratorModel> _generators = [];
  bool _isLoading = false;

  List<GeneratorModel> get generators => _generators;
  bool get isLoading => _isLoading;

  Future<void> loadGenerators() async {
    _isLoading = true;
    notifyListeners();

    _generators = await _dao.getAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addGenerator(GeneratorModel generator) async {
    final id = await _dao.insert(generator);
    if (id > 0) {
      await loadGenerators();
      return true;
    }
    return false;
  }

  Future<bool> updateGenerator(GeneratorModel generator) async {
    final rows = await _dao.update(generator);
    if (rows > 0) {
      await loadGenerators();
      return true;
    }
    return false;
  }

  Future<bool> deleteGenerator(int id) async {
    final rows = await _dao.delete(id);
    if (rows > 0) {
      await loadGenerators();
      return true;
    }
    return false;
  }

  Future<bool> updateFuel(int id, double newFuel) async {
    final rows = await _dao.updateFuel(id, newFuel);
    if (rows > 0) {
      await loadGenerators();
      return true;
    }
    return false;
  }
}