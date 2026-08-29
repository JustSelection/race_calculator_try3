import 'package:flutter/foundation.dart';
import '../models/analytics_event_model.dart';
import '../services/analytics_event_dao.dart';

class AnalyticsEventProvider extends ChangeNotifier {
  final AnalyticsEventDao _dao = AnalyticsEventDao();
  
  List<AnalyticsEventModel> _events = [];
  bool _isLoading = false;

  List<AnalyticsEventModel> get events => _events;
  bool get isLoading => _isLoading;

  Future<void> loadEvents({String? type}) async {
    _isLoading = true;
    notifyListeners();
    _events = type != null 
        ? await _dao.getByType(type) 
        : await _dao.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addEvent(AnalyticsEventModel event) async {
    final id = await _dao.insert(event);
    if (id > 0) {
      await loadEvents();
      return true;
    }
    return false;
  }

  Future<bool> deleteEvent(int id) async {
    final rows = await _dao.delete(id);
    if (rows > 0) {
      await loadEvents();
      return true;
    }
    return false;
  }
}