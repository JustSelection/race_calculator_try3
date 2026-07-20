class OptimizationModel {
  final int? id;
  final int generatorId;
  final DateTime date;
  final double fuelAmount;
  final String comment;

  OptimizationModel({
    this.id,
    required this.generatorId,
    required this.date,
    required double fuelAmount,
    required this.comment,
  }) : fuelAmount = _round(fuelAmount);

  // Жесткое округление до сотых
  static double _round(double value) => 
      double.parse(value.toStringAsFixed(2));

  OptimizationModel copyWith({
    int? id,
    int? generatorId,
    DateTime? date,
    double? fuelAmount,
    String? comment,
  }) {
    return OptimizationModel(
      id: id ?? this.id,
      generatorId: generatorId ?? this.generatorId,
      date: date ?? this.date,
      fuelAmount: fuelAmount ?? this.fuelAmount,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'generatorId': generatorId,
      'date': date.toIso8601String(),
      'fuelAmount': fuelAmount,
      'comment': comment,
    };
  }

  factory OptimizationModel.fromMap(Map<String, dynamic> map) {
    return OptimizationModel(
      id: map['id'] as int?,
      generatorId: map['generatorId'] as int,
      date: DateTime.parse(map['date'] as String),
      fuelAmount: (map['fuelAmount'] as num).toDouble(),
      comment: map['comment'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptimizationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}