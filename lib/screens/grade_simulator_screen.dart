import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/grade_item.dart';
import '../services/storage_service.dart';
import '../widgets/grade_row.dart';

class GradeSimulatorScreen extends StatefulWidget {
  const GradeSimulatorScreen({super.key});

  @override
  State<GradeSimulatorScreen> createState() => _GradeSimulatorScreenState();
}

class _GradeSimulatorScreenState extends State<GradeSimulatorScreen> {
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  final double _passingGrade = 4.0;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subs = await StorageService.loadSubjects();
    setState(() {
      _subjects = subs;
      if (subs.isNotEmpty) {
        _selectedSubject = subs.first;
      }
    });
  }

  void _addGradeEvaluation() {
    if (_selectedSubject == null) return;
    final nameCtrl = TextEditingController(
      text: 'Evaluación ${_selectedSubject!.gradeItems.length + 1}',
    );
    final weightCtrl = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej. Certamen 1)',
              ),
            ),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ponderación (%)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(weightCtrl.text) ?? 0.0;
              final newItem = GradeItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                weightPercentage: weight,
              );
              setState(() => _selectedSubject!.gradeItems.add(newItem));
              await StorageService.saveSubjects(_subjects);
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_subjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Simulador de Notas'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No tienes asignaturas creadas.\nPrimero registra tus ramos en la pestaña "Ramos" para simular notas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final items = _selectedSubject?.gradeItems ?? [];
    double currentEarnedPoints = 0.0;
    double evaluatedWeight = 0.0;
    double totalWeight = 0.0;

    for (var item in items) {
      totalWeight += item.weightPercentage;
      if (item.score != null) {
        currentEarnedPoints += (item.score! * (item.weightPercentage / 100));
        evaluatedWeight += item.weightPercentage;
      }
    }

    final currentAverage = evaluatedWeight > 0
        ? (currentEarnedPoints / (evaluatedWeight / 100))
        : 0.0;
    final remainingWeight = 100.0 - evaluatedWeight;
    final neededPoints = _passingGrade - currentEarnedPoints;
    final requiredScore = remainingWeight > 0
        ? (neededPoints / (remainingWeight / 100))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Notas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar Evaluación',
            onPressed: _addGradeEvaluation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<Subject>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Asignatura',
                border: OutlineInputBorder(),
              ),
              items: _subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.code} - ${s.name}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedSubject = val),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Promedio Actual Ponderado:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      evaluatedWeight > 0
                          ? currentAverage.toStringAsFixed(2)
                          : 'Sin notas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentAverage >= _passingGrade
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avance evaluado: ${evaluatedWeight.toStringAsFixed(0)}% / ${totalWeight.toStringAsFixed(0)}%',
                    ),
                    Text(
                      'Falta por evaluar: ${remainingWeight.toStringAsFixed(0)}%',
                    ),
                  ],
                ),
                const Divider(),
                if (remainingWeight > 0 && requiredScore != null)
                  Text(
                    requiredScore <= 1.0
                        ? '🎉 ¡Ya alcanzaste la nota 4.0 para aprobar!'
                        : requiredScore > 7.0
                        ? '⚠️ Necesitas más de un 7.0 (${requiredScore.toStringAsFixed(2)}) en el resto para llegar a 4.0.'
                        : '🎯 Para aprobar con 4.0 necesitas promediar un ${requiredScore.toStringAsFixed(2)} en el $remainingWeight% restante.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: requiredScore > 7.0
                          ? Colors.red.shade900
                          : Colors.teal.shade900,
                    ),
                    textAlign: TextAlign.center,
                  )
                else if (remainingWeight == 0)
                  Text(
                    currentEarnedPoints >= _passingGrade
                        ? '✅ Asignatura Aprobada (${currentEarnedPoints.toStringAsFixed(2)})'
                        : '❌ Asignatura Reprobada (${currentEarnedPoints.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentEarnedPoints >= _passingGrade
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Presiona "+" para añadir evaluaciones (certámenes, laboratorios, etc.).',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (ctx, index) {
                      final item = items[index];
                      return GradeRow(
                        item: item,
                        onDelete: () async {
                          setState(
                            () => _selectedSubject!.gradeItems.removeAt(index),
                          );
                          await StorageService.saveSubjects(_subjects);
                        },
                        onScoreChanged: (newScore) async {
                          setState(() => item.score = newScore);
                          await StorageService.saveSubjects(_subjects);
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
