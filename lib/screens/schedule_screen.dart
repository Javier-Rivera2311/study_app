import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/class_schedule.dart';
import '../services/storage_service.dart';
import '../widgets/schedule_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Subject> _subjects = [];
  List<ClassSchedule> _schedules = [];
  String _selectedDay = 'Lunes';
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
    String day = _selectedDay;
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final roomCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Agregar Bloque de Clase'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                DropdownButtonFormField<String>(
                  value: day,
                  decoration: const InputDecoration(labelText: 'Día'),
                  items: _weekDays
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) => setDlgState(() => day = val!),
                ),
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
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (startCtrl.text.isEmpty || endCtrl.text.isEmpty) return;
                final newSchedule = ClassSchedule(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  subjectId: selectedSub.id,
                  subjectName: selectedSub.name,
                  day: day,
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                  room: roomCtrl.text.trim().isEmpty
                      ? 'Por definir'
                      : roomCtrl.text.trim(),
                  colorValue: selectedSub.colorValue,
                );
                setState(() => _schedules.add(newSchedule));
                await StorageService.saveSchedules(_schedules);
                Navigator.pop(ctx);
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
    final currentDaySchedules =
        _schedules.where((s) => s.day == _selectedDay).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

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
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
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
          const Divider(),
          Expanded(
            child: currentDaySchedules.isEmpty
                ? Center(
                    child: Text(
                      'No tienes clases registradas el $_selectedDay.',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: currentDaySchedules.length,
                    itemBuilder: (context, index) {
                      final item = currentDaySchedules[index];
                      return ScheduleCard(
                        schedule: item,
                        onDelete: () async {
                          setState(
                            () =>
                                _schedules.removeWhere((s) => s.id == item.id),
                          );
                          await StorageService.saveSchedules(_schedules);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
