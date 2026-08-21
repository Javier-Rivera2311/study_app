# ESTRUCTURA Y CONTEXTO DEL PROYECTO: UNIVERSITY ACADEMIC HUB

## 1. INFORMACION GENERAL
- Nombre del Proyecto: University Academic Hub / Gestor Académico Universitario
- Framework: Flutter (Dart) con Material 3
- Plataformas: Android / iOS
- Persistencia: Almacenamiento Local Offline-First usando SharedPreferences y JSON
- Base de datos inicial: 100% limpia (sin datos mock ni valores predeterminados)
- Objetivo: Gestión integral de ramos cursados, horario semanal con vistas flexibles, plan de estudio con temporizador Pomodoro háptico/sonoro y simulador predictivo de notas.

## 2. ARQUITECTURA DE DATOS Y MODELOS

### Nodo: Subject (Asignatura)
- Atributos:
  * id (String): Identificador unico
  * code (String): Codigo de la asignatura (ej. ICI222)
  * name (String): Nombre del ramo
  * credits (int): Creditos SCT
  * colorValue (int): Color en formato hexadecimal para tarjetas y chips
  * gradeItems (List<GradeItem>): Lista de evaluaciones asociadas
- Persistencia: Clave 'user_subjects_key' en SharedPreferences

### Nodo: ClassSchedule (Bloque de Horario)
- Atributos:
  * id (String): Identificador unico
  * subjectId (String): Referencia a la asignatura padre
  * subjectName (String): Nombre de la asignatura
  * day (String): Dia de la semana (Lunes a Sabado)
  * startTime (String): Hora de inicio (ej. 10:15)
  * endTime (String): Hora de termino (ej. 11:45)
  * room (String): Sala o laboratorio
  * colorValue (int): Color heredado de la asignatura
- Persistencia: Clave 'user_schedules_key' en SharedPreferences

### Nodo: StudyTask (Bloque de Plan de Estudio)
- Atributos:
  * id (String): Identificador unico
  * day (String): Dia asignado
  * subjectName (String): Materia o ramo a estudiar
  * timeSlot (String): Rango horario (ej. 07:15 - 08:45)
  * plannedHours (double): Horas estimadas
  * isCompleted (bool): Estado del checkbox de cumplimiento
- Persistencia: Clave 'user_tasks_key' en SharedPreferences

### Nodo: GradeItem (Evaluacion / Certamen)
- Atributos:
  * id (String): Identificador unico
  * name (String): Nombre de la evaluacion (ej. Certamen 1, Taller)
  * weightPercentage (double): Ponderacion en porcentaje (ej. 30.0)
  * score (double?): Nota obtenida (escala 1.0 a 7.0) o null si esta pendiente

## 3. MODULOS Y FUNCIONALIDADES DE LA INTERFAZ

### A. Modulo "Mis Ramos" (SubjectsScreen)
- Listado de todas las asignaturas activas registradas por el usuario.
- Formulario de creacion con selector de color tematico y creditos SCT.
- Eliminacion de ramos.

### B. Modulo "Horario" (ScheduleScreen)
- Selector de vista dual:
  * Vista Diaria: Filtrado por chips de dias individuales.
  * Toda la Semana: Visualizacion completa en acordeon expandible de Lunes a Sabado.
- Creacion rapida con repeticion multidia: Permite seleccionar varios dias mediante FilterChips para duplicar la misma clase con un solo clic.

### C. Modulo "Estudio" (StudyTrackerScreen)
- Temporizador Pomodoro Integrado:
  * Modos: Enfoque (25 min), Descanso Corto (5 min), Descanso Largo (15 min).
  * Selector desplegable responsivo para vincular el Pomodoro a una tarea especifica.
  * Alarma y feedback de finalizacion: Emite SystemSound.alert y vibracion HapticFeedback.heavyImpact.
  * Marcado rapido de tarea completada directamente desde el panel del temporizador.
- Checklist semanal agrupado por dia con calculo de horas cumplidas vs planificadas.

### D. Modulo "Simulador" (GradeSimulatorScreen)
- Selector de asignatura para evaluar.
- Formulario dinamico de evaluaciones y ponderaciones.
- Tarjeta responsiva de proyeccion automatica:
  * Promedio actual ponderado.
  * Porcentaje total evaluado y porcentaje restante.
  * Formula de nota necesaria para aprobar con nota minima 4.0:
    Nota Necesaria = (4.0 - Puntos Ganados) / (Ponderacion Restante / 100)
    donde Puntos Ganados = Suma de (Nota_i * Ponderacion_i / 100).
  * Mensajes de alerta: Aprobado garantizado, Reprobado matematico (> 7.0 requerido) o meta proyectada.
- Boton de accion flotante centrado en la parte inferior (centerFloat).

## 4. ESTRUCTURA DE CODIGO Y ARCHIVOS DEL PROYECTO
- lib/main.dart: Punto de entrada con MaterialApp y configuracion del tema Material 3.
- lib/models/subject.dart: Modelo y serializacion de asignaturas.
- lib/models/class_schedule.dart: Modelo y serializacion de clases.
- lib/models/study_task.dart: Modelo y serializacion de tareas de estudio.
- lib/models/grade_item.dart: Modelo y serializacion de calificaciones.
- lib/services/storage_service.dart: Metodos async para persistencia local en SharedPreferences.
- lib/widgets/task_tile.dart: Tarjeta interactiva para la lista de tareas.
- lib/widgets/schedule_card.dart: Tarjeta para los bloques de horario.
- lib/widgets/grade_row.dart: Fila editable para notas y ponderaciones.
- lib/screens/main_navigation_screen.dart: Shell con NavigationBar e IndexedStack para las 4 pantallas.
- lib/screens/subjects_screen.dart: Pantalla de gestion de asignaturas.
- lib/screens/schedule_screen.dart: Pantalla de horarios con vista diaria y semanal.
- lib/screens/study_tracker_screen.dart: Pantalla de plan de estudio con Pomodoro.
- lib/screens/grade_simulator_screen.dart: Pantalla del simulador predictivo de notas.
