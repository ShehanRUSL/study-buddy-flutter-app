import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(StudyBuddyApp());
}

class StudyBuddyApp extends StatelessWidget {
  const StudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Buddy',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Map<String, List<String>> plannerTasks = {};
  List<String> todoTasks = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ---------------- LOCAL STORAGE: LOAD DATA ----------------
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    String? plannerJson = prefs.getString("plannerTasks");
    String? todoJson = prefs.getString("todoTasks");

    if (plannerJson != null) {
      plannerTasks = Map<String, List<String>>.from(
        jsonDecode(
          plannerJson,
        ).map((key, value) => MapEntry(key, List<String>.from(value))),
      );
    }

    if (todoJson != null) {
      todoTasks = List<String>.from(jsonDecode(todoJson));
    }

    setState(() {});
  }

  // ---------------- LOCAL STORAGE: SAVE DATA ----------------
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("plannerTasks", jsonEncode(plannerTasks));
    await prefs.setString("todoTasks", jsonEncode(todoTasks));
  }

  // ---------------- Add/Delete Logic ----------------
  void _addTaskToPlanner(String dateKey, String task) {
    if (!plannerTasks.containsKey(dateKey)) {
      plannerTasks[dateKey] = [];
    }
    plannerTasks[dateKey]!.add(task);
    todoTasks.add(task);
    saveData();
    setState(() {});
  }

  void _deletePlannerTask(String dateKey, int index) {
    plannerTasks[dateKey]!.removeAt(index);
    saveData();
    setState(() {});
  }

  void _completeTodoTask(int index) {
    todoTasks.removeAt(index);
    saveData();
    setState(() {});
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      PomodoroTimerPage(),
      StudyPlannerPage(
        plannerTasks: plannerTasks,
        onAddTask: _addTaskToPlanner,
        onDeleteTask: _deletePlannerTask,
      ),
      TodoListPage(todoTasks: todoTasks, onComplete: _completeTodoTask),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa8e063), Color(0xFF56ab2f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  'Study Buddy',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Expanded(child: pages[_selectedIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.green[700],
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'To-Do',
          ),
        ],
      ),
    );
  }
}

// ------------------ Pomodoro Timer ------------------
class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  _PomodoroTimerPageState createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage>
    with SingleTickerProviderStateMixin {
  static const int _initialTime = 1500; // 25 minutes
  int _secondsRemaining = _initialTime;
  bool _isRunning = false;
  Timer? _timer;

  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _initialTime),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _animationController?.forward(from: 0);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _isRunning = false;
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _animationController?.stop();
    _isRunning = false;
  }

  void _resetTimer() {
    _timer?.cancel();
    _animationController?.reset();
    setState(() {
      _secondsRemaining = _initialTime;
      _isRunning = false;
    });
  }

  String _format(int sec) =>
      '${(sec ~/ 60).toString().padLeft(2, "0")}:${(sec % 60).toString().padLeft(2, "0")}';

  @override
  Widget build(BuildContext context) {
    double progress = (_initialTime - _secondsRemaining) / _initialTime;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.white30,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                _format(_secondsRemaining),
                style: TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _btn("Start", _startTimer),
              SizedBox(width: 20),
              _btn("Pause", _pauseTimer),
              SizedBox(width: 20),
              _btn("Reset", _resetTimer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String t, VoidCallback f) {
    return ElevatedButton(
      onPressed: f,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[700],
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(
        t,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ------------------ Planner Page ------------------
class StudyPlannerPage extends StatefulWidget {
  final Map<String, List<String>> plannerTasks;
  final Function(String, String) onAddTask;
  final Function(String, int) onDeleteTask;

  const StudyPlannerPage({
    super.key,
    required this.plannerTasks,
    required this.onAddTask,
    required this.onDeleteTask,
  });

  @override
  _StudyPlannerPageState createState() => _StudyPlannerPageState();
}

class _StudyPlannerPageState extends State<StudyPlannerPage> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dateKey = _selectedDate.toString().split(' ')[0];
    final tasks = widget.plannerTasks[dateKey] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pick Date
          ElevatedButton(
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text(
              'Pick Date: $dateKey',
              style: TextStyle(color: Colors.green[700]),
            ),
          ),
          SizedBox(height: 10),
          // Add Task
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Enter study task',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final task = _controller.text.trim();
                  if (task.isNotEmpty) {
                    widget.onAddTask(dateKey, task);
                    _controller.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green[700],
                ),
                child: Text('Add'),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Display Tasks
          Expanded(
            child:
                tasks.isEmpty
                    ? Text(
                      "No tasks for this day",
                      style: TextStyle(color: Colors.white70),
                    )
                    : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder:
                          (context, index) => Card(
                            child: ListTile(
                              title: Text(tasks[index]),
                              subtitle: Text(dateKey),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed:
                                    () => widget.onDeleteTask(dateKey, index),
                              ),
                            ),
                          ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ------------------ Todo List ------------------
class TodoListPage extends StatelessWidget {
  final List<String> todoTasks;
  final Function(int) onComplete;

  const TodoListPage({
    super.key,
    required this.todoTasks,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child:
          todoTasks.isEmpty
              ? Center(
                child: Text(
                  "No To-Do tasks",
                  style: TextStyle(color: Colors.white),
                ),
              )
              : ListView.builder(
                itemCount: todoTasks.length,
                itemBuilder:
                    (context, index) => Card(
                      child: ListTile(
                        title: Text(todoTasks[index]),
                        trailing: CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 16,
                          child: IconButton(
                            icon: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () => onComplete(index),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),
                    ),
              ),
    );
  }
}
