import 'package:flutter/material.dart';
import '../models/study_task.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import '../widgets/task_tile.dart';

class StudyTrackerScreen extends StatefulWidget {
  const StudyTrackerScreen({super.key});

  @override
  State<StudyTrackerScreen> createState() => _StudyTrackerScreenState();
}

class _StudyTrackerScreenState extends State<StudyTrackerScreen> {
  List<StudyTask> _tasks = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  final List<String> _weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await StorageService.loadTasks();
    final subs = await StorageService.loadSubjects();
    setState(() {
      _tasks = tasks;
      _subjects = subs;
      _isLoading = false;
    });
  }

  void _showAddTaskDialog() {
    String day = 'Lunes';
    String subjectName = _subjects.isNotEmpty ? _subjects.first.name : '';
    final customSubCtrl = TextEditingController();
    final timeSlotCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '1.5');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Nuevo Bloque de Estudio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: day,
                  decoration: const InputDecoration(labelText: 'Día'),
                  items: _weekDays
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) => setDlgState(() => day = val!),
                ),
                if (_subjects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: subjectName,
                    decoration: const InputDecoration(labelText: 'Asignatura'),
                    items: _subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.name,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDlgState(() => subjectName = val!),
                  )
                else
                  TextField(
                    controller: customSubCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Asignatura o Materia',
                    ),
                  ),
                TextField(
                  controller: timeSlotCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Horario (ej. 07:15 - 08:45)',
                  ),
                ),
                TextField(
                  controller: hoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Horas planeadas',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedName = _subjects.isNotEmpty
                    ? subjectName
                    : customSubCtrl.text.trim();
                if (selectedName.isEmpty) return;
                final newTask = StudyTask(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  day: day,
                  subjectName: selectedName,
                  timeSlot: timeSlotCtrl.text.trim().isEmpty
                      ? 'Flexible'
                      : timeSlotCtrl.text.trim(),
                  plannedHours: double.tryParse(hoursCtrl.text) ?? 1.5,
                );
                setState(() => _tasks.add(newTask));
                await StorageService.saveTasks(_tasks);
                Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTask(StudyTask task, bool? value) async {
    setState(() => task.isCompleted = value ?? false);
    await StorageService.saveTasks(_tasks);
  }

  Future<void> _resetWeek() async {
    setState(() {
      for (var task in _tasks) {
        task.isCompleted = false;
      }
    });
    await StorageService.saveTasks(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final completedHours = _tasks
        .where((t) => t.isCompleted)
        .fold(0.0, (sum, t) => sum + t.plannedHours);
    final totalHours = _tasks.fold(0.0, (sum, t) => sum + t.plannedHours);
    final progress = totalHours > 0 ? (completedHours / totalHours) : 0.0;
    final days = _tasks.map((t) => t.day).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de Estudio'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar Semana',
            onPressed: _resetWeek,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _tasks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No tienes bloques de estudio creados.\nPresiona "+" para planificar tus sesiones de estudio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progreso Semanal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${completedHours.toStringAsFixed(1)} / ${totalHours.toStringAsFixed(1)} hrs',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                        backgroundColor: Colors.teal.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final dayTasks = _tasks
                          .where((t) => t.day == day)
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              top: 12,
                              bottom: 4,
                            ),
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...dayTasks.map(
                            (task) => TaskTile(
                              task: task,
                              onChanged: (val) => _toggleTask(task, val),
                              onDelete: () async {
                                setState(
                                  () => _tasks.removeWhere(
                                    (t) => t.id == task.id,
                                  ),
                                );
                                await StorageService.saveTasks(_tasks);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
