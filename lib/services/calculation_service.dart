class CalculationException implements Exception {
  final String message;
  CalculationException(this.message);
  
  @override
  String toString() => message;
}

class CalculationResult {
  final int distance;
  final double fuelConsumed;
  final double remainingFuel;

  CalculationResult({
    required this.distance,
    required this.fuelConsumed,
    required this.remainingFuel,
  });
}

class CalculationService {
  // Жесткое округление до сотых
  static double _round(double value) => 
      double.parse(value.toStringAsFixed(2));

  /// Выполняет расчет рейса.
  /// Возвращает CalculationResult или бросает CalculationException.
  static CalculationResult calculate({
    required int startMileage,
    required int endMileage,
    required double fuelAtDeparture,
    required double refueled,
    required double fuelConsumption, // л/100км из профиля авто
  }) {
    // 1. Строгая валидация входных данных (защита от некорректного ввода)
    if (startMileage < 0) {
      throw CalculationException('Начальный пробег не может быть отрицательным.');
    }
    if (endMileage <= startMileage) {
      throw CalculationException('Конечный пробег должен быть строго больше начального.');
    }
    if (fuelConsumption <= 0) {
      throw CalculationException('Расход топлива должен быть больше 0.');
    }
    if (fuelAtDeparture < 0) {
      throw CalculationException('Топливо на момент выезда не может быть отрицательным.');
    }
    if (refueled < 0) {
      throw CalculationException('Количество заправленного топлива не может быть отрицательным.');
    }

    // 2. Математические расчеты
    final int distance = endMileage - startMileage;
    
    // Затрачено топлива по паспортному расходу
    final double fuelConsumed = _round((distance * fuelConsumption) / 100.0);
    
    // Остаток топлива в баке (Баланс: было + заправили - ушло)
    final double remainingFuel = _round(fuelAtDeparture + refueled - fuelConsumed);
    
    // Проверка на абсурдные значения (ушло больше, чем было в баке + заправка)
    if (remainingFuel < 0) {
      throw CalculationException(
        'Ошибка расчета: остаток топлива не может быть отрицательным. '
        'Проверьте начальный уровень топлива и расход.'
      );
    }

    return CalculationResult(
      distance: distance,
      fuelConsumed: fuelConsumed,
      remainingFuel: remainingFuel,
    );
  }
}