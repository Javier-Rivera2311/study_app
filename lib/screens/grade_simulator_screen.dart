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
    final weightCtrl = TextEditingController(text: '25');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nueva Evaluación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej. Certamen 1)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Ponderación (%)',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final weight =
                  double.tryParse(weightCtrl.text.replaceAll(',', '.')) ?? 0.0;
              final newItem = GradeItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                weightPercentage: weight,
              );
              setState(() => _selectedSubject!.gradeItems.add(newItem));
              await StorageService.saveSubjects(_subjects);
              if (mounted) Navigator.pop(ctx);
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
              'No tienes asignaturas registradas.\nPrimero agrega tus ramos en la pestaña "Mis Ramos".',
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
      ),
      // BOTÓN CENTRADO EN LA PARTE INFERIOR
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: _addGradeEvaluation,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Agregar Evaluación',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          // Selector de Asignatura
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<Subject>(
              value: _selectedSubject,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Seleccionar Asignatura',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              items: _subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        '${s.code} - ${s.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedSubject = val),
            ),
          ),

          // Tarjeta de Resultados Responsiva
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.teal.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Promedio actual
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Promedio Actual Ponderado:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      evaluatedWeight > 0
                          ? currentAverage.toStringAsFixed(2)
                          : 'Sin notas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: currentAverage >= _passingGrade
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progreso porcentual
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Avance: ${evaluatedWeight.toStringAsFixed(0)}% / ${totalWeight.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Por evaluar: ${remainingWeight.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 16),

                // Proyección de nota necesaria
                if (remainingWeight > 0 && requiredScore != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        requiredScore > 7.0
                            ? Icons.warning_amber_rounded
                            : Icons.track_changes,
                        color: requiredScore > 7.0
                            ? Colors.red.shade800
                            : Colors.teal.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          requiredScore <= 1.0
                              ? '¡Ya aseguraste la aprobación con nota 4.0!'
                              : requiredScore > 7.0
                              ? 'Necesitas más de un 7.0 (${requiredScore.toStringAsFixed(2)}) en lo restante para llegar a 4.0.'
                              : 'Para aprobar con 4.0 necesitas promediar un ${requiredScore.toStringAsFixed(2)} en el $remainingWeight% restante.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: requiredScore > 7.0
                                ? Colors.red.shade900
                                : Colors.teal.shade900,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (remainingWeight == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        currentEarnedPoints >= _passingGrade
                            ? Icons.check_circle_outline
                            : Icons.highlight_off,
                        color: currentEarnedPoints >= _passingGrade
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentEarnedPoints >= _passingGrade
                            ? 'Asignatura Aprobada (${currentEarnedPoints.toStringAsFixed(2)})'
                            : 'Asignatura Reprobada (${currentEarnedPoints.toStringAsFixed(2)})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: currentEarnedPoints >= _passingGrade
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Lista de Evaluaciones
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No hay evaluaciones registradas.\nPresiona "Agregar Evaluación" abajo para comenzar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      90,
                    ), // Espacio suficiente para no tapar ítems con el botón centrado
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
