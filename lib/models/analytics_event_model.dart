class AnalyticsEventModel {
  final int? id;
  final String type; // 'refuel', 'inventory', 'optimization', 'transfer', 'calibration'
  final DateTime date;
  final String description;
  final int? relatedId; // ID связанного объекта (агрегата, заправки и т.д.)

  AnalyticsEventModel({
    this.id,
    required this.type,
    required this.date,
    required this.description,
    this.relatedId,
  });

  AnalyticsEventModel copyWith({
    int? id,
    String? type,
    DateTime? date,
    String? description,
    int? relatedId,
  }) {
    return AnalyticsEventModel(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
      'description': description,
      'relatedId': relatedId,
    };
  }

  factory AnalyticsEventModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsEventModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String,
      relatedId: map['relatedId'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsEventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}