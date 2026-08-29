class InventoryModel {
  final int? id;
  final int generatorId;
  final DateTime date;
  final double previousFuel;
  final double actualFuel;
  final double difference;

  InventoryModel({
    this.id,
    required this.generatorId,
    required this.date,
    required double previousFuel,
    required double actualFuel,
    required double difference,
  })  : previousFuel = _round(previousFuel),
        actualFuel = _round(actualFuel),
        difference = _round(difference);

  // Жесткое округление до сотых
  static double _round(double value) =>
      double.parse(value.toStringAsFixed(2));

  InventoryModel copyWith({
    int? id,
    int? generatorId,
    DateTime? date,
    double? previousFuel,
    double? actualFuel,
    double? difference,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      generatorId: generatorId ?? this.generatorId,
      date: date ?? this.date,
      previousFuel: previousFuel ?? this.previousFuel,
      actualFuel: actualFuel ?? this.actualFuel,
      difference: difference ?? this.difference,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'generatorId': generatorId,
      'date': date.toIso8601String(),
      'previousFuel': previousFuel,
      'actualFuel': actualFuel,
      'difference': difference,
    };
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: map['id'] as int?,
      generatorId: map['generatorId'] as int,
      date: DateTime.parse(map['date'] as String),
      previousFuel: (map['previousFuel'] as num).toDouble(),
      actualFuel: (map['actualFuel'] as num).toDouble(),
      difference: (map['difference'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}