import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/class_schedule.dart';
import '../models/study_task.dart';

class StorageService {
  static const String _subjectsKey = 'user_subjects_key';
  static const String _schedulesKey = 'user_schedules_key';
  static const String _tasksKey = 'user_tasks_key';

  // --- Asignaturas ---
  static Future<List<Subject>> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_subjectsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => Subject.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return []; // Inicia vacío
  }

  static Future<void> saveSubjects(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(subjects.map((s) => s.toMap()).toList());
    await prefs.setString(_subjectsKey, jsonStr);
  }

  // --- Horarios de Clases ---
  static Future<List<ClassSchedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_schedulesKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => ClassSchedule.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return []; // Inicia vacío
  }

  static Future<void> saveSchedules(List<ClassSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(schedules.map((s) => s.toMap()).toList());
    await prefs.setString(_schedulesKey, jsonStr);
  }

  // --- Plan de Estudio ---
  static Future<List<StudyTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_tasksKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => StudyTask.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return []; // Inicia vacío
  }

  static Future<void> saveTasks(List<StudyTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_tasksKey, jsonStr);
  }
}
