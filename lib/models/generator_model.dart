class GeneratorModel {
  final int? id;
  final int? carId; // Привязка к автомобилю (null = не привязан / временно не используется)
  final String name; // Например: "Генератор", "Канистра 20 л"
  final double capacity; // Полный объем бака агрегата
  final double currentFuel; // Фактическое количество топлива

  GeneratorModel({
    this.id,
    this.carId,
    required this.name,
    required double capacity,
    required double currentFuel,
  })  : capacity = _round(capacity),
        currentFuel = _round(currentFuel);

  // Жесткое округление до сотых
  static double _round(double value) => 
      double.parse(value.toStringAsFixed(2));

  GeneratorModel copyWith({
    int? id,
    int? carId,
    String? name,
    double? capacity,
    double? currentFuel,
  }) {
    return GeneratorModel(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      currentFuel: currentFuel ?? this.currentFuel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'name': name,
      'capacity': capacity,
      'currentFuel': currentFuel,
    };
  }

  factory GeneratorModel.fromMap(Map<String, dynamic> map) {
    return GeneratorModel(
      id: map['id'] as int?,
      carId: map['carId'] as int?,
      name: map['name'] as String,
      capacity: (map['capacity'] as num).toDouble(),
      currentFuel: (map['currentFuel'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneratorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}