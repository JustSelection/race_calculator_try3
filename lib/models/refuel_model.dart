class RefuelModel {
  final int? id;
  final DateTime date;
  final double totalFuel;
  final String? comment;

  RefuelModel({
    this.id,
    required this.date,
    required double totalFuel,
    this.comment,
  }) : totalFuel = _round(totalFuel);

  static double _round(double value) =>
      double.parse(value.toStringAsFixed(2));

  RefuelModel copyWith({
    int? id,
    DateTime? date,
    double? totalFuel,
    String? comment,
  }) {
    return RefuelModel(
      id: id ?? this.id,
      date: date ?? this.date,
      totalFuel: totalFuel ?? this.totalFuel,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'totalFuel': totalFuel,
      'comment': comment,
    };
  }

  factory RefuelModel.fromMap(Map<String, dynamic> map) {
    return RefuelModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      totalFuel: (map['totalFuel'] as num).toDouble(),
      comment: map['comment'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefuelModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}