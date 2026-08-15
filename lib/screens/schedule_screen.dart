import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/class_schedule.dart';
import '../services/storage_service.dart';
import '../widgets/schedule_card.dart';

enum ScheduleViewMode { daily, weekly }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Subject> _subjects = [];
  List<ClassSchedule> _schedules = [];
  String _selectedDay = 'Lunes';
  ScheduleViewMode _viewMode = ScheduleViewMode.daily;
  final List<String> _weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final subs = await StorageService.loadSubjects();
    final scheds = await StorageService.loadSchedules();
    setState(() {
      _subjects = subs;
      _schedules = scheds;
    });
  }

  void _showAddClassDialog() {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes registrar asignaturas en "Mis Ramos" antes de agregar clases.',
          ),
        ),
      );
      return;
    }

    Subject selectedSub = _subjects.first;
    Set<String> selectedDays = {_selectedDay};
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final roomCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Agregar Bloque de Clase',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Subject>(
                  value: selectedSub,
                  decoration: const InputDecoration(labelText: 'Asignatura'),
                  items: _subjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDlgState(() => selectedSub = val!),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Repetir en los días:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _weekDays.map((d) {
                    final isChecked = selectedDays.contains(d);
                    return FilterChip(
                      label: Text(d),
                      selected: isChecked,
                      selectedColor: Colors.teal.shade100,
                      checkmarkColor: Colors.teal,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isChecked
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isChecked
                            ? Colors.teal.shade900
                            : Colors.black87,
                      ),
                      onSelected: (bool selected) {
                        setDlgState(() {
                          if (selected) {
                            selectedDays.add(d);
                          } else {
                            if (selectedDays.length > 1) {
                              selectedDays.remove(d);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Inicio (ej. 10:15)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fin (ej. 11:45)',
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sala / Laboratorio',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (startCtrl.text.isEmpty || endCtrl.text.isEmpty) return;

                final String roomText = roomCtrl.text.trim().isEmpty
                    ? 'Por definir'
                    : roomCtrl.text.trim();
                final int baseTime = DateTime.now().millisecondsSinceEpoch;

                final newEntries = selectedDays.toList().asMap().entries.map((
                  entry,
                ) {
                  final int index = entry.key;
                  final String dayName = entry.value;
                  return ClassSchedule(
                    id: '${baseTime}_$index',
                    subjectId: selectedSub.id,
                    subjectName: selectedSub.name,
                    day: dayName,
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                    room: roomText,
                    colorValue: selectedSub.colorValue,
                  );
                }).toList();

                setState(() {
                  _schedules.addAll(newEntries);
                });
                await StorageService.saveSchedules(_schedules);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario de Clases'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Selector de Vista: Por Día vs Toda la Semana
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: SegmentedButton<ScheduleViewMode>(
              segments: const [
                ButtonSegment<ScheduleViewMode>(
                  value: ScheduleViewMode.daily,
                  icon: Icon(Icons.view_day_outlined),
                  label: Text('Vista Diaria'),
                ),
                ButtonSegment<ScheduleViewMode>(
                  value: ScheduleViewMode.weekly,
                  icon: Icon(Icons.calendar_view_week_outlined),
                  label: Text('Toda la Semana'),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (Set<ScheduleViewMode> newSelection) {
                setState(() {
                  _viewMode = newSelection.first;
                });
              },
            ),
          ),

          // Contenido según el modo de vista seleccionado
          if (_viewMode == ScheduleViewMode.daily) ...[
            // Chips de días para vista diaria
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _weekDays.length,
                itemBuilder: (context, index) {
                  final d = _weekDays[index];
                  final isSelected = d == _selectedDay;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(d),
                      selected: isSelected,
                      selectedColor: Colors.teal,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDay = d);
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildDailyView()),
          ] else ...[
            const Divider(height: 1),
            Expanded(child: _buildWeeklyView()),
          ],
        ],
      ),
    );
  }

  // Widget para la Vista Diaria
  Widget _buildDailyView() {
    final currentDaySchedules =
        _schedules.where((s) => s.day == _selectedDay).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (currentDaySchedules.isEmpty) {
      return Center(
        child: Text(
          'No tienes clases registradas el $_selectedDay.',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: currentDaySchedules.length,
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemBuilder: (context, index) {
        final item = currentDaySchedules[index];
        return ScheduleCard(
          schedule: item,
          onDelete: () async {
            setState(() => _schedules.removeWhere((s) => s.id == item.id));
            await StorageService.saveSchedules(_schedules);
          },
        );
      },
    );
  }

  // Widget para la Vista de Toda la Semana
  Widget _buildWeeklyView() {
    if (_schedules.isEmpty) {
      return const Center(
        child: Text(
          'No tienes clases registradas en toda la semana.',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _weekDays.length,
      itemBuilder: (context, index) {
        final day = _weekDays[index];
        final daySchedules = _schedules.where((s) => s.day == day).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: daySchedules.isNotEmpty,
              leading: Icon(
                Icons.calendar_today,
                color: daySchedules.isNotEmpty ? Colors.teal : Colors.grey,
                size: 20,
              ),
              title: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: daySchedules.isNotEmpty ? Colors.black87 : Colors.grey,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: daySchedules.isNotEmpty
                      ? Colors.teal.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: daySchedules.isNotEmpty
                        ? Colors.teal.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  '${daySchedules.length} ${daySchedules.length == 1 ? 'clase' : 'clases'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: daySchedules.isNotEmpty
                        ? Colors.teal.shade800
                        : Colors.grey,
                  ),
                ),
              ),
              children: daySchedules.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Sin clases este día',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ]
                  : daySchedules.map((item) {
                      final itemColor = Color(item.colorValue);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(color: itemColor, width: 4),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            item.subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '⏰ ${item.startTime} - ${item.endTime}  |  📍 ${item.room}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              setState(
                                () => _schedules.removeWhere(
                                  (s) => s.id == item.id,
                                ),
                              );
                              await StorageService.saveSchedules(_schedules);
                            },
                          ),
                        ),
                      );
                    }).toList(),
            ),
          ),
        );
      },
    );
  }
}
