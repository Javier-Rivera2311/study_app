import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final list = await StorageService.loadSubjects();
    setState(() {
      _subjects = list;
      _isLoading = false;
    });
  }

  void _showAddSubjectDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: '4');
    int selectedColor = 0xFF0288D1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Nueva Asignatura Cursada'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Asignatura',
                  ),
                ),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código (ej. ICI222)',
                  ),
                ),
                TextField(
                  controller: creditsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Créditos SCT'),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Color identificador:'),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children:
                      [
                            0xFF0288D1,
                            0xFF2E7D32,
                            0xFFF57C00,
                            0xFFFBC02D,
                            0xFFD32F2F,
                            0xFF7B1FA2,
                            0xFF009688,
                          ]
                          .map(
                            (col) => GestureDetector(
                              onTap: () =>
                                  setDlgState(() => selectedColor = col),
                              child: CircleAvatar(
                                backgroundColor: Color(col),
                                radius: 14,
                                child: selectedColor == col
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          )
                          .toList(),
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
                if (nameCtrl.text.trim().isEmpty) return;
                final newSub = Subject(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  code: codeCtrl.text.trim().toUpperCase(),
                  name: nameCtrl.text.trim(),
                  credits: int.tryParse(creditsCtrl.text) ?? 4,
                  colorValue: selectedColor,
                );
                setState(() => _subjects.add(newSub));
                await StorageService.saveSubjects(_subjects);
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Asignaturas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showAddSubjectDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _subjects.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No tienes asignaturas registradas.\nPresiona el botón "+" para agregar las asignaturas que estás cursando.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final sub = _subjects[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(sub.colorValue),
                      child: Text(
                        sub.code.length >= 3
                            ? sub.code.substring(0, 3)
                            : sub.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      sub.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Código: ${sub.code} • Créditos: ${sub.credits} SCT',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () async {
                        setState(() => _subjects.removeAt(index));
                        await StorageService.saveSubjects(_subjects);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
