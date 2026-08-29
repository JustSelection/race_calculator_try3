class CalibrationModel {
  final int? id;
  final DateTime date;
  final String comment;

  CalibrationModel({
    this.id,
    required this.date,
    required this.comment,
  });

  CalibrationModel copyWith({
    int? id,
    DateTime? date,
    String? comment,
  }) {
    return CalibrationModel(
      id: id ?? this.id,
      date: date ?? this.date,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'comment': comment,
    };
  }

  factory CalibrationModel.fromMap(Map<String, dynamic> map) {
    return CalibrationModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      comment: map['comment'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalibrationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}