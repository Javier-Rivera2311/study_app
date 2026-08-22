import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/study_task.dart';

enum PomodoroMode { focus, shortBreak, longBreak }

class PomodoroTimerCard extends StatefulWidget {
  final List<StudyTask> tasks;
  final StudyTask? activeTask;
  final ValueChanged<StudyTask?> onActiveTaskChanged;
  final void Function(StudyTask task, bool isCompleted) onToggleTask;

  const PomodoroTimerCard({
    super.key,
    required this.tasks,
    required this.activeTask,
    required this.onActiveTaskChanged,
    required this.onToggleTask,
  });

  @override
  State<PomodoroTimerCard> createState() => _PomodoroTimerCardState();
}

class _PomodoroTimerCardState extends State<PomodoroTimerCard> {
  // Estados internos del temporizador
  PomodoroMode _pomodoroMode = PomodoroMode.focus;
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;

  static const int _focusDuration = 25 * 60;
  static const int _shortBreakDuration = 5 * 60;
  static const int _longBreakDuration = 15 * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
        backgroundColor: const Color.fromARGB(255, 1, 110, 98),
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (widget.tasks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StudyTask>(
                  value: widget.tasks.contains(widget.activeTask)
                      ? widget.activeTask
                      : widget.tasks.first,
                  dropdownColor: Colors.teal.shade900,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 20,
                  ),
                  isDense: true,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: widget.tasks.map((task) {
                    return DropdownMenuItem(
                      value: task,
                      child: Text(
                        '${task.day}: ${task.subjectName} (${task.timeSlot})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: widget.onActiveTaskChanged,
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
                icon: const Icon(Icons.replay, color: Colors.white70, size: 22),
                tooltip: 'Reiniciar',
                onPressed: _resetTimer,
              ),
              if (widget.activeTask != null)
                IconButton(
                  icon: Icon(
                    widget.activeTask!.isCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: widget.activeTask!.isCompleted
                        ? Colors.greenAccent
                        : Colors.white70,
                    size: 22,
                  ),
                  tooltip: 'Marcar completado',
                  onPressed: () => widget.onToggleTask(
                    widget.activeTask!,
                    !widget.activeTask!.isCompleted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
