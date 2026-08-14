class StudyTask {
  final String id;
  final String day;
  final String subjectName;
  final String timeSlot;
  final double plannedHours;
  bool isCompleted;

  StudyTask({
    required this.id,
    required this.day,
    required this.subjectName,
    required this.timeSlot,
    required this.plannedHours,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'day': day,
    'subjectName': subjectName,
    'timeSlot': timeSlot,
    'plannedHours': plannedHours,
    'isCompleted': isCompleted,
  };

  factory StudyTask.fromMap(Map<String, dynamic> map) => StudyTask(
    id: map['id'] as String,
    day: map['day'] as String,
    subjectName: map['subjectName'] as String,
    timeSlot: map['timeSlot'] as String,
    plannedHours: (map['plannedHours'] as num).toDouble(),
    isCompleted: map['isCompleted'] as bool? ?? false,
  );
}
