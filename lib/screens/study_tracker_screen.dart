import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/study_task.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import '../widgets/task_tile.dart';

enum PomodoroMode { focus, shortBreak, longBreak }

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

  // --- Estados del Temporizador Pomodoro ---
  PomodoroMode _pomodoroMode = PomodoroMode.focus;
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  StudyTask? _activeTask;

  static const int _focusDuration = 25 * 60;
  static const int _shortBreakDuration = 1 * 60;
  static const int _longBreakDuration = 15 * 60;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  void _startTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _onPomodoroCompleted();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      switch (_pomodoroMode) {
        case PomodoroMode.focus:
          _remainingSeconds = _focusDuration;
          break;
        case PomodoroMode.shortBreak:
          _remainingSeconds = _shortBreakDuration;
          break;
        case PomodoroMode.longBreak:
          _remainingSeconds = _longBreakDuration;
          break;
      }
    });
  }

  void _switchPomodoroMode(PomodoroMode mode) {
    _pauseTimer();
    setState(() {
      _pomodoroMode = mode;
      switch (mode) {
        case PomodoroMode.focus:
          _remainingSeconds = _focusDuration;
          break;
        case PomodoroMode.shortBreak:
          _remainingSeconds = _shortBreakDuration;
          break;
        case PomodoroMode.longBreak:
          _remainingSeconds = _longBreakDuration;
          break;
      }
    });
  }

  void _onPomodoroCompleted() {
    _timer?.cancel();
    setState(() => _isRunning = false);

    // Sonido de alerta nativo del sistema y vibración
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();

    String message = _pomodoroMode == PomodoroMode.focus
        ? '¡Sesión de enfoque completada! Tómate un descanso.'
        : '¡Descanso finalizado! Hora de volver al estudio.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.alarm_on, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.teal.shade800,
        duration: const Duration(seconds: 4),
      ),
    );

    if (_pomodoroMode == PomodoroMode.focus) {
      _switchPomodoroMode(PomodoroMode.shortBreak);
    } else {
      _switchPomodoroMode(PomodoroMode.focus);
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
          // 1. Tarjeta Pomodoro Responsiva
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _pomodoroMode == PomodoroMode.focus
                      ? [Colors.teal.shade700, Colors.teal.shade900]
                      : [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Selector de Modos Pomodoro
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildModeChip('Enfoque', PomodoroMode.focus),
                      _buildModeChip('Descanso', PomodoroMode.shortBreak),
                      _buildModeChip('D. Largo', PomodoroMode.longBreak),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Cronómetro
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  // Selector de Tarea Activa Responsivo
                  if (_tasks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<StudyTask>(
                          value: _tasks.contains(_activeTask)
                              ? _activeTask
                              : _tasks.first,
                          dropdownColor: Colors.teal.shade900,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                            size: 20,
                          ),
                          isDense: true,
                          isExpanded: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          items: _tasks.map((task) {
                            return DropdownMenuItem(
                              value: task,
                              child: Text(
                                '${task.day}: ${task.subjectName} (${task.timeSlot})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _activeTask = val),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Botones de Control
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal.shade900,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isRunning ? _pauseTimer : _startTimer,
                        icon: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          size: 20,
                        ),
                        label: Text(
                          _isRunning ? 'Pausar' : 'Iniciar',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.replay,
                          color: Colors.white70,
                          size: 22,
                        ),
                        tooltip: 'Reiniciar',
                        onPressed: _resetTimer,
                      ),
                      if (_activeTask != null)
                        IconButton(
                          icon: Icon(
                            _activeTask!.isCompleted
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: _activeTask!.isCompleted
                                ? Colors.greenAccent
                                : Colors.white70,
                            size: 22,
                          ),
                          tooltip: 'Marcar completado',
                          onPressed: () => _toggleTask(
                            _activeTask!,
                            !_activeTask!.isCompleted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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
                        onChanged: (val) => _toggleTask(task, val),
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

  Widget _buildModeChip(String label, PomodoroMode mode) {
    final isSelected = _pomodoroMode == mode;
    return GestureDetector(
      onTap: () => _switchPomodoroMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.teal.shade900 : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
