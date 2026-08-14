class GradeItem {
  final String id;
  String name;
  double weightPercentage;
  double? score;

  GradeItem({
    required this.id,
    required this.name,
    required this.weightPercentage,
    this.score,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'weightPercentage': weightPercentage,
    'score': score,
  };

  factory GradeItem.fromMap(Map<String, dynamic> map) => GradeItem(
    id: map['id'] as String,
    name: map['name'] as String,
    weightPercentage: (map['weightPercentage'] as num).toDouble(),
    score: map['score'] != null ? (map['score'] as num).toDouble() : null,
  );
}
