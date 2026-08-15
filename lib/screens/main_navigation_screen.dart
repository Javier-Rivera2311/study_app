import 'package:flutter/material.dart';
import 'subjects_screen.dart';
import 'schedule_screen.dart';
import 'study_tracker_screen.dart';
import 'grade_simulator_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SubjectsScreen(),
    ScheduleScreen(),
    StudyTrackerScreen(),
    GradeSimulatorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bookmark),
            label: 'Asignaturas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Horario',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl),
            label: 'Estudio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            label: 'Simulador',
          ),
        ],
      ),
    );
  }
}
