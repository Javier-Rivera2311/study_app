class ClassSchedule {
  final String id;
  final String subjectId;
  final String subjectName;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final int colorValue;

  ClassSchedule({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'day': day,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'colorValue': colorValue,
  };

  factory ClassSchedule.fromMap(Map<String, dynamic> map) => ClassSchedule(
    id: map['id'] as String,
    subjectId: map['subjectId'] as String,
    subjectName: map['subjectName'] as String,
    day: map['day'] as String,
    startTime: map['startTime'] as String,
    endTime: map['endTime'] as String,
    room: map['room'] as String,
    colorValue: map['colorValue'] as int,
  );
}
