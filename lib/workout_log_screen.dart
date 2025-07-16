import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});
  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  String formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> addWorkout() async {
    String? name;
    TimeOfDay? start, end;

    int? calculateDuration(TimeOfDay? start, TimeOfDay? end) {
      if (start == null || end == null) return null;
      final now = DateTime.now();
      final dtStart = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      final dtEnd = DateTime(now.year, now.month, now.day, end.hour, end.minute);
      int diff = dtEnd.difference(dtStart).inMinutes;
      if (diff < 0) diff += 24 * 60;
      return diff;
    }

    String formatTimeOfDay(TimeOfDay t) {
      final dt = DateTime(0, 0, 0, t.hour, t.minute);
      return TimeOfDay.fromDateTime(dt).format(context);
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final duration = calculateDuration(start, end);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Text("Add Workout", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text("Workout Name", style: TextStyle(color: Colors.indigo[400], fontSize: 14)),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "e.g. Running, Pushups",
                        border: UnderlineInputBorder(),
                      ),
                      onChanged: (v) => name = v,
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[100],
                              minimumSize: Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Start: ",
                                    style: TextStyle(
                                      color: Colors.indigo[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: start != null ? formatTimeOfDay(start!) : "--:--",
                                    style: TextStyle(
                                      color: Colors.indigo[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                  context: context, initialTime: start ?? TimeOfDay.now());
                              if (picked != null) setState(() => start = picked);
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[100],
                              minimumSize: Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "End: ",
                                    style: TextStyle(
                                      color: Colors.indigo[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: end != null ? formatTimeOfDay(end!) : "--:--",
                                    style: TextStyle(
                                      color: Colors.indigo[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                  context: context, initialTime: end ?? TimeOfDay.now());
                              if (picked != null) setState(() => end = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    if (start != null && end != null)
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.indigo[400]),
                          SizedBox(width: 8),
                          Text(
                            "Duration: ${duration ?? 0} min",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  child: Text("Add"),
                  onPressed: () {
                    if (name != null && start != null && end != null && duration != null) {
                      Navigator.pop(ctx, {
                        "name": name,
                        "startTime": formatTimeOfDay(start!),
                        "endTime": formatTimeOfDay(end!),
                        "duration": duration,
                        "done": false,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            );
          },
        );
      }
    );
    if (result != null) {
      final dateKey = formatDate(selectedDate);
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid)
        .collection('logs').doc(dateKey);
      final docSnap = await docRef.get();
      final d = docSnap.data() ?? {};
      final List<Map<String, dynamic>> workouts = List<Map<String, dynamic>>.from(d['workouts'] ?? []);
      workouts.add(result);
      await docRef.set({'workouts': workouts}, SetOptions(merge: true));
    }
  }

  Future<void> deleteWorkout(
      int idx, List<Map<String, dynamic>> workouts, DocumentReference dateDoc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Workout"),
        content: Text("Are you sure you want to delete this workout?"),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(ctx, false)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
              child: Text("Delete"),
              onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirm == true) {
      workouts.removeAt(idx);
      await dateDoc.update({'workouts': workouts});
    }
  }

  String normalizeTime(String? value) {
    if (value == null) return '--';
    try {
      final dt = DateFormat.jm().parse(value);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = formatDate(selectedDate);
    final dateDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('logs')
        .doc(dateKey);

    final isToday = dateKey == formatDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text("Workout Log", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.indigo),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
            tooltip: "Pick a date",
          )
        ],
      ),
      floatingActionButton: isToday
        ? FloatingActionButton.extended(
            onPressed: addWorkout,
            label: Text("Add Workout"),
            icon: Icon(Icons.add),
            backgroundColor: Colors.indigo[400],
          )
        : null,
      body: StreamBuilder<DocumentSnapshot>(
        stream: dateDoc.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          final d = snap.data!.data() as Map<String, dynamic>? ?? {};
          final raw = d['workouts'];
          final List<Map<String, dynamic>> workouts =
              (raw is List)
                  ? raw.where((e) => e is Map).map((e) => Map<String, dynamic>.from(e)).toList()
                  : [];
          return ListView(
            padding: EdgeInsets.all(18),
            children: [
              ...workouts.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(child: Text("No workouts for this day")),
                      ),
                    ]
                  : workouts.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final w = entry.value;
                      return Card(
                        color: w['done'] == true ? Colors.green[100] : Colors.indigo[100],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: isToday
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[700]),
                                  tooltip: "Delete workout",
                                  onPressed: () => deleteWorkout(idx, workouts, dateDoc),
                                )
                              : Icon(Icons.fitness_center, color: Colors.indigo[800]),
                          title: Text(
                            w['name'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.indigo[700], size: 18),
                                  SizedBox(width: 5),
                                  Text(
                                    "${normalizeTime(w['startTime'])} - ${normalizeTime(w['endTime'])}",
                                    style: TextStyle(
                                      color: Colors.indigo[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.timer, color: Colors.indigo[400], size: 16),
                                  SizedBox(width: 5),
                                  Text(
                                    "Duration: ${w['duration'] ?? '--'} mins",
                                    style: TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isToday
                              ? IconButton(
                                  icon: Icon(
                                    w['done'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: w['done'] == true ? Colors.green : Colors.grey,
                                  ),
                                  tooltip: w['done'] == true ? "Mark as not done" : "Mark as done",
                                  onPressed: () async {
                                    workouts[idx]['done'] = !(w['done'] == true);
                                    await dateDoc.update({'workouts': workouts});
                                  },
                                )
                              : null,
                        ),
                      );
                    }),
            ],
          );
        },
      ),
    );
  }
}
