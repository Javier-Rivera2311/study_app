import 'package:flutter/material.dart';
import '../models/study_task.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import '../widgets/task_tile.dart';
import '../widgets/pomodoro_timer_card.dart'; // <--- Importamos el nuevo widget

class StudyTrackerScreen extends StatefulWidget {
  const StudyTrackerScreen({super.key});

  @override
  State<StudyTrackerScreen> createState() => _StudyTrackerScreenState();
}

class _StudyTrackerScreenState extends State<StudyTrackerScreen> {
  List<StudyTask> _tasks = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  StudyTask? _activeTask;

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
      if (_tasks.isNotEmpty) {
        _activeTask = _tasks.firstWhere(
          (t) => !t.isCompleted,
          orElse: () => _tasks.first,
        );
      }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Nuevo Bloque de Estudio',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: day,
                  decoration: const InputDecoration(
                    labelText: 'Día',
                    border: OutlineInputBorder(),
                  ),
                  items: _weekDays
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) => setDlgState(() => day = val!),
                ),
                const SizedBox(height: 10),
                if (_subjects.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: subjectName,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Asignatura',
                      border: OutlineInputBorder(),
                    ),
                    items: _subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.name,
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: timeSlotCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Horario (ej. 07:15 - 08:45)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hoursCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Horas planeadas',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
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
                  plannedHours:
                      double.tryParse(hoursCtrl.text.replaceAll(',', '.')) ??
                      1.5,
                );
                setState(() {
                  _tasks.add(newTask);
                  _activeTask ??= newTask;
                });
                await StorageService.saveTasks(_tasks);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTask(StudyTask task, bool value) async {
    setState(() => task.isCompleted = value);
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
        title: const Text('Plan de Estudio & Pomodoro'),
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
      body: CustomScrollView(
        slivers: [
          // 1. Tarjeta Pomodoro (ahora encapsulada en un widget limpio)
          SliverToBoxAdapter(
            child: PomodoroTimerCard(
              tasks: _tasks,
              activeTask: _activeTask,
              onActiveTaskChanged: (StudyTask? newTask) {
                setState(() => _activeTask = newTask);
              },
              onToggleTask: _toggleTask,
            ),
          ),

          // 2. Barra de Progreso Semanal
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Progreso de Horas Semanales',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${completedHours.toStringAsFixed(1)} / ${totalHours.toStringAsFixed(1)} hrs',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: Colors.teal.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Lista de Tareas por Día
          if (_tasks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No tienes bloques de estudio creados.\nPresiona "+" para planificar tus sesiones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final day = days[index];
                final dayTasks = _tasks.where((t) => t.day == day).toList();
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...dayTasks.map(
                      (task) => TaskTile(
                        task: task,
                        onChanged: (val) => _toggleTask(task, val ?? false),
                        onDelete: () async {
                          setState(() {
                            _tasks.removeWhere((t) => t.id == task.id);
                            if (_activeTask?.id == task.id) {
                              _activeTask = _tasks.isNotEmpty
                                  ? _tasks.first
                                  : null;
                            }
                          });
                          await StorageService.saveTasks(_tasks);
                        },
                      ),
                    ),
                  ],
                );
              }, childCount: days.length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
