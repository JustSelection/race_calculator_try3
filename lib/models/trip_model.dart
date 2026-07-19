class Trip {
  final int? id;
  final int carId;
  final DateTime date;
  
  // Ввод пользователя
  final int startMileage;
  final int endMileage;
  final double fuelAtDeparture; // Топливо на момент выезда
  final double refueled;        // Заправлено
  
  // Главный результат
  final double remainingFuel;   // Остаток

  Trip({
    this.id,
    required this.carId,
    required this.date,
    required this.startMileage,
    required this.endMileage,
    required double fuelAtDeparture,
    required double refueled,
    required double remainingFuel,
  })  : fuelAtDeparture = _round(fuelAtDeparture),
        refueled = _round(refueled),
        remainingFuel = _round(remainingFuel);

  static double _round(double value) => 
      double.parse(value.toStringAsFixed(2));

  // Вычисляемые поля (гарантируют, что они всегда верны)
  int get distance => endMileage - startMileage;
  double get fuelConsumed => _round(fuelAtDeparture + refueled - remainingFuel);

  Trip copyWith({
    int? id,
    int? carId,
    DateTime? date,
    int? startMileage,
    int? endMileage,
    double? fuelAtDeparture,
    double? refueled,
    double? remainingFuel,
  }) {
    return Trip(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      date: date ?? this.date,
      startMileage: startMileage ?? this.startMileage,
      endMileage: endMileage ?? this.endMileage,
      fuelAtDeparture: fuelAtDeparture ?? this.fuelAtDeparture,
      refueled: refueled ?? this.refueled,
      remainingFuel: remainingFuel ?? this.remainingFuel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'date': date.toIso8601String(),
      'startMileage': startMileage,
      'endMileage': endMileage,
      'fuelAtDeparture': fuelAtDeparture,
      'refueled': refueled,
      'remainingFuel': remainingFuel,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      date: DateTime.parse(map['date'] as String),
      startMileage: (map['startMileage'] as num).toInt(),
      endMileage: (map['endMileage'] as num).toInt(),
      fuelAtDeparture: (map['fuelAtDeparture'] as num).toDouble(),
      refueled: (map['refueled'] as num).toDouble(),
      remainingFuel: (map['remainingFuel'] as num).toDouble(),
    );
  }
}
