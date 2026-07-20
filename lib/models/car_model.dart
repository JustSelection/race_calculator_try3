class Car {
  final int? id;
  final String brand;
  final String licensePlate;
  final double fuelConsumption; // л/100км
  final int currentMileage;     // км
  final double fuelInTank;      // л
  final double tankCapacity;    // л

  Car({
    this.id,
    required this.brand,
    required this.licensePlate,
    required this.fuelConsumption,
    required this.currentMileage,
    required double fuelInTank,
    required double tankCapacity,
  })  : fuelInTank = _round(fuelInTank),
        tankCapacity = _round(tankCapacity);

  // Жесткое округление до сотых
  static double _round(double value) => 
      double.parse(value.toStringAsFixed(2));

  Car copyWith({
    int? id,
    String? brand,
    String? licensePlate,
    double? fuelConsumption,
    int? currentMileage,
    double? fuelInTank,
    double? tankCapacity,
  }) {
    return Car(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      licensePlate: licensePlate ?? this.licensePlate,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      currentMileage: currentMileage ?? this.currentMileage,
      fuelInTank: fuelInTank ?? this.fuelInTank,
      tankCapacity: tankCapacity ?? this.tankCapacity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'licensePlate': licensePlate,
      'fuelConsumption': fuelConsumption,
      'currentMileage': currentMileage,
      'fuelInTank': fuelInTank,
      'tankCapacity': tankCapacity,
    };

    
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as int?,
      brand: map['brand'] as String,
      licensePlate: map['licensePlate'] as String,
      fuelConsumption: (map['fuelConsumption'] as num).toDouble(),
      currentMileage: (map['currentMileage'] as num).toInt(),
      fuelInTank: (map['fuelInTank'] as num).toDouble(),
      tankCapacity: (map['tankCapacity'] as num).toDouble(),
    );
  }
    @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Car && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}