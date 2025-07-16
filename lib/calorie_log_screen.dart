import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class CalorieLogScreen extends StatefulWidget {
  const CalorieLogScreen({super.key});

  @override
  State<CalorieLogScreen> createState() => _CalorieLogScreenState();
}

class _CalorieLogScreenState extends State<CalorieLogScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, double>> getGoals() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final d = doc.data() ?? {};
    return {
      'calories': (d['targetCalories'] ?? 2000).toDouble(),
      'water': (d['targetWater'] ?? 2.5).toDouble(),
    };
  }

  Future<void> _logValue(String field, String label, String unit) async {
    double? val = await showDialog<double>(
      context: context,
      builder: (ctx) {
        double _input = 0;
        return AlertDialog(
          title: Text("Log $label"),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: "$label ($unit)"),
            onChanged: (v) => _input = double.tryParse(v) ?? 0,
          ),
          actions: [
            TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(ctx)),
            ElevatedButton(child: Text("Save"), onPressed: () => Navigator.pop(ctx, _input)),
          ],
        );
      },
    );
    if (val != null && val > 0) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('logs').doc(today).set({
        field: FieldValue.increment(val),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _clearValue(String field) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('logs').doc(today).set({
      field: 0,
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getLast7Logs() {
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 6));
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('logs')
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map((snap) {
      return List.generate(7, (i) {
        final day = sevenDaysAgo.add(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(day);
        QueryDocumentSnapshot<Map<String, dynamic>>? doc;
        try {
          doc = snap.docs.firstWhere((d) => d.id == dateKey);
        } catch (e) {
          doc = null;
        }
        final data = doc?.data() ?? {};
        return {
          'date': dateKey,
          'calories': (data['calories'] ?? 0.0).toDouble(),
          'water': (data['water'] ?? 0.0).toDouble(),
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nutrition & Water", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, double>>(
        future: getGoals(),
        builder: (context, goalsSnap) {
          if (!goalsSnap.hasData) return Center(child: CircularProgressIndicator());
          final userGoals = goalsSnap.data!;
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

          final todayDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('logs')
              .doc(today)
              .snapshots();

          return StreamBuilder<DocumentSnapshot>(
            stream: todayDoc,
            builder: (context, snap) {
              if (!snap.hasData) return Center(child: CircularProgressIndicator());
              final d = snap.data!.data() as Map<String, dynamic>? ?? {};
              final calories = (d['calories'] ?? 0.0).toDouble();
              final water = (d['water'] ?? 0.0).toDouble();

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: getLast7Logs(),
                builder: (context, logsSnap) {
                  final logs = logsSnap.data ??
                      List.generate(7, (i) {
                        final dt = DateTime.now().subtract(Duration(days: 6 - i));
                        return {'date': DateFormat('yyyy-MM-dd').format(dt), 'calories': 0.0, 'water': 0.0};
                      });

                  return ListView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      SizedBox(height: 12),
                      _ProgressCard(
                        label: "Calories Consumed",
                        value: calories,
                        goal: userGoals['calories']!,
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                        unit: "kcal",
                        onAdd: () => _logValue('calories', 'Calories', 'kcal'),
                        onClear: () => _clearValue('calories'),
                      ),
                      SizedBox(height: 14),
                      _ProgressCard(
                        label: "Water Drank",
                        value: water,
                        goal: userGoals['water']!,
                        icon: Icons.local_drink,
                        color: Colors.blue,
                        unit: "L",
                        onAdd: () => _logValue('water', 'Water', 'L'),
                        onClear: () => _clearValue('water'),
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: Text(
                          "Last 7 Days",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: 1.3,
                        child: NutritionBarChart(
                          logs: logs,
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String label, unit;
  final double value, goal;
  final IconData icon;
  final Color color;
  final VoidCallback onAdd;
  final VoidCallback onClear;
  const _ProgressCard({
    required this.label,
    required this.value,
    required this.goal,
    required this.icon,
    required this.color,
    required this.unit,
    required this.onAdd,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value / goal).clamp(0.0, 1.0);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.13),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: percent,
                    color: color,
                    backgroundColor: color.withOpacity(0.08),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${value.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)} $unit",
                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: color),
              onPressed: onAdd,
              tooltip: "Add $label",
            ),
            IconButton(
              icon: Icon(Icons.clear, color: Colors.red[400]),
              onPressed: onClear,
              tooltip: "Clear $label",
            ),
          ],
        ),
      ),
    );
  }
}

class NutritionBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  const NutritionBarChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final caloriesMax = 4000.0;
    final waterMax = 4000.0;
    final labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: caloriesMax,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final log = logs[group.x.toInt()];
              if (rodIndex == 0) {
                final realCalories = (log['calories'] ?? 0.0).toDouble();
                return BarTooltipItem(
                  "Calories: ${realCalories.toInt()} kcal",
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                );
              } else {
                final realWater = (log['water'] ?? 0.0).toDouble();
                final realWaterMl = (realWater * 1000).toInt();
                return BarTooltipItem(
                  "Water: ${realWaterMl} mL",
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                );
              }
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              interval: 500,
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == 0) return Text('0');
                if (value % 1000 == 0) return Text('${(value ~/ 1000)}K');
                if (value % 500 == 0) return Text('${(value ~/ 500) / 2}K');
                return SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= logs.length) return SizedBox();
                final date = DateTime.parse(logs[idx]['date']);
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(DateFormat('MM/dd').format(date), style: labelStyle),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 500),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(logs.length, (idx) {
          final cal = (logs[idx]['calories'] ?? 0.0).toDouble();
          final waterL = (logs[idx]['water'] ?? 0.0).toDouble();
          final realWaterMl = waterL * 1000;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: cal > caloriesMax ? caloriesMax : cal,
                color: Colors.orange,
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: realWaterMl > waterMax ? waterMax : realWaterMl,
                color: Colors.blue,
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            showingTooltipIndicators: [],
          );
        }),
        groupsSpace: 24,
      ),
    );
  }
}
