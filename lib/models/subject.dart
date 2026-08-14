import 'grade_item.dart';

class Subject {
  final String id;
  String code;
  String name;
  int credits;
  int colorValue;
  List<GradeItem> gradeItems;

  Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.colorValue,
    List<GradeItem>? gradeItems,
  }) : gradeItems = gradeItems ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'name': name,
    'credits': credits,
    'colorValue': colorValue,
    'gradeItems': gradeItems.map((g) => g.toMap()).toList(),
  };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
    id: map['id'] as String,
    code: map['code'] as String,
    name: map['name'] as String,
    credits: map['credits'] as int,
    colorValue: map['colorValue'] as int,
    gradeItems:
        (map['gradeItems'] as List<dynamic>?)
            ?.map((g) => GradeItem.fromMap(g as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
