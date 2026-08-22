# 🎓 University Academic Hub (Gestor Académico Universitario)

Este documento sirve como mapa arquitectónico y de contexto del proyecto. Está estructurado para ser fácilmente interpretado tanto por desarrolladores como por asistentes de Inteligencia Artificial.

## 1. ℹ️ Información General
* **Nombre del Proyecto:** University Academic Hub / Gestor Académico Universitario
* **Framework:** Flutter (Dart) con Material 3
* **Plataformas:** Android / iOS
* **Persistencia:** Almacenamiento Local Offline-First usando `SharedPreferences` y JSON.
* **Base de datos inicial:** 100% limpia (sin datos mock ni valores predeterminados).
* **Objetivo:** Gestión integral de ramos cursados, horario semanal con vistas flexibles, plan de estudio con temporizador Pomodoro háptico/sonoro y simulador predictivo de notas.

---

## 2. 🗄️ Arquitectura de Datos y Modelos

### 📦 Nodo: `Subject` (Asignatura)
* **Persistencia:** Clave `user_subjects_key` en SharedPreferences.
* **Atributos:**
  * `id` (String): Identificador único.
  * `code` (String): Código de la asignatura (ej. ICI222).
  * `name` (String): Nombre del ramo.
  * `credits` (int): Créditos SCT.
  * `colorValue` (int): Color en formato hexadecimal para tarjetas y chips.
  * `gradeItems` (List<GradeItem>): Lista de evaluaciones asociadas.

### 📅 Nodo: `ClassSchedule` (Bloque de Horario)
* **Persistencia:** Clave `user_schedules_key` en SharedPreferences.
* **Atributos:**
  * `id` (String): Identificador único.
  * `subjectId` (String): Referencia a la asignatura padre.
  * `subjectName` (String): Nombre de la asignatura.
  * `day` (String): Día de la semana (Lunes a Sábado).
  * `startTime` (String): Hora de inicio (ej. 10:15).
  * `endTime` (String): Hora de término (ej. 11:45).
  * `room` (String): Sala o laboratorio.
  * `colorValue` (int): Color heredado de la asignatura.

### 📝 Nodo: `StudyTask` (Bloque de Plan de Estudio)
* **Persistencia:** Clave `user_tasks_key` en SharedPreferences.
* **Atributos:**
  * `id` (String): Identificador único.
  * `day` (String): Día asignado.
  * `subjectName` (String): Materia o ramo a estudiar.
  * `timeSlot` (String): Rango horario (ej. 07:15 - 08:45).
  * `plannedHours` (double): Horas estimadas.
  * `isCompleted` (bool): Estado del checkbox de cumplimiento.

### 💯 Nodo: `GradeItem` (Evaluación / Certamen)
* **Atributos:**
  * `id` (String): Identificador único.
  * `name` (String): Nombre de la evaluación (ej. Certamen 1, Taller).
  * `weightPercentage` (double): Ponderación en porcentaje (ej. 30.0).
  * `score` (double?): Nota obtenida (escala 1.0 a 7.0) o `null` si está pendiente.

---

## 3. 📱 Módulos y Funcionalidades de la Interfaz

### A. Módulo "Mis Ramos" (`SubjectsScreen`)
* Listado de todas las asignaturas activas registradas por el usuario.
* Formulario de creación con selector de color temático y créditos SCT.
* Eliminación de ramos (borrado en cascada visual).

### B. Módulo "Horario" (`ScheduleScreen`)
* **Selector de vista dual:** Vista Diaria (filtrado por chips) vs. Toda la Semana (acordeón expandible).
* **Creación multidía:** Repetición mediante `FilterChips` para duplicar la misma clase en varios días con un solo clic.

### C. Módulo "Estudio" (`StudyTrackerScreen` & `PomodoroTimerCard`)
* **Temporizador Pomodoro Integrado:** Enfoque (25 min), Descanso Corto (5 min), Descanso Largo (15 min).
* **Vinculación:** Selector desplegable responsivo para asociar el reloj a una tarea de estudio específica.
* **Feedback Háptico/Sonoro:** Emite `SystemSound.alert` y `HapticFeedback.heavyImpact` al finalizar el ciclo.
* **Gestión Rápida:** Marcado de tarea completada directamente desde el panel del temporizador.
* **Progreso:** Checklist semanal agrupado por día con cálculo de horas cumplidas vs. planificadas.

### D. Módulo "Simulador" (`GradeSimulatorScreen`)
* Selector dinámico de asignatura a evaluar.
* Formulario de ingreso de evaluaciones y ponderaciones porcentuales.
* **Tarjeta responsiva de proyección:** Muestra promedio actual ponderado y porcentaje evaluado.
* **Lógica Matemática Predictiva:** 
  * `Nota Necesaria = (4.0 - Puntos Ganados) / (Ponderación Restante / 100)`
* **Alertas Inteligentes:** Avisa si ya se aprobó el ramo, si es matemáticamente imposible (requiere > 7.0), o muestra la nota exacta necesaria.
* Botón de acción flotante (FAB) grande y centrado (`centerFloat`).

---

## 4. 📂 Estructura de Archivos (Directorios)

* `lib/main.dart`: Punto de entrada, rutas y configuración de Material 3.
* **`/models/`**
  * `subject.dart`: Lógica de entidad de asignatura.
  * `class_schedule.dart`: Lógica de entidad de horarios.
  * `study_task.dart`: Lógica de entidad de tareas de estudio.
  * `grade_item.dart`: Lógica de entidad de calificaciones.
* **`/services/`**
  * `storage_service.dart`: Puente asíncrono con SharedPreferences para serializar/deserializar JSON.
* **`/widgets/`**
  * `pomodoro_timer_card.dart`: Encapsulación completa de UI y lógica del temporizador.
  * `task_tile.dart`: Tarjeta visual para las tareas de la lista.
  * `schedule_card.dart`: Elemento visual de bloque horario.
  * `grade_row.dart`: Fila interactiva para calcular notas.
* **`/screens/`**
  * `main_navigation_screen.dart`: Contenedor principal con BottomNavigationBar e IndexedStack.
  * `subjects_screen.dart`: Vista del módulo de asignaturas.
  * `schedule_screen.dart`: Vista del módulo de horarios.
  * `study_tracker_screen.dart`: Vista del módulo de estudio y lista de tareas.
  * `grade_simulator_screen.dart`: Vista del simulador predictivo.