import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SleepLogScreen extends StatefulWidget {
  const SleepLogScreen({super.key});
  @override
  State<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends State<SleepLogScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _editSleep(double? currentValue) async {
    double? newVal = await showDialog<double>(
      context: context,
      builder: (ctx) {
        double _input = currentValue ?? 0;
        return AlertDialog(
          title: Text("Log Sleep (hours)"),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: "Sleep (h)"),
            controller: TextEditingController(
              text: _input > 0 ? _input.toString() : "",
            ),
            onChanged: (v) => _input = double.tryParse(v) ?? 0,
          ),
          actions: [
            TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(ctx)),
            ElevatedButton(child: Text("Save"), onPressed: () => Navigator.pop(ctx, _input)),
          ],
        );
      },
    );
    if (newVal != null) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('logs').doc(today).set({
        'sleep': newVal,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _clearSleep() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('logs').doc(today).set({
      'sleep': 0,
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
          'sleep': (data['sleep'] ?? 0.0).toDouble(),
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('logs')
        .doc(today)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text("Sleep Tracker", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: todayDoc,
        builder: (context, snap) {
          final d = snap.data?.data() as Map<String, dynamic>? ?? {};
          final sleep = (d['sleep'] ?? 0.0).toDouble();

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: getLast7Logs(),
            builder: (context, logsSnap) {
              final logs = logsSnap.data ??
                  List.generate(7, (i) {
                    final dt = DateTime.now().subtract(Duration(days: 6 - i));
                    return {'date': DateFormat('yyyy-MM-dd').format(dt), 'sleep': 0.0};
                  });

              return ListView(
                padding: EdgeInsets.symmetric(horizontal: 8),
                children: [
                  SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 6,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.nightlight, color: Colors.purple, size: 28),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              sleep > 0
                                  ? "Last Night's Sleep: ${sleep.toStringAsFixed(1)} h"
                                  : "No sleep logged for today!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (sleep > 0)
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.purple[400]),
                              onPressed: () => _editSleep(sleep),
                            ),
                          if (sleep > 0)
                            IconButton(
                              icon: Icon(Icons.clear, color: Colors.red[300]),
                              onPressed: _clearSleep,
                            ),
                          if (sleep == 0)
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.purple[400]),
                              onPressed: () => _editSleep(0),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Text(
                      "Past 7 Nights",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  SizedBox(height: 14),
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: SleepBarChart(logs: logs),
                  ),
                  SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class SleepBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  const SleepBarChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    final maxY = 14.0;
    final labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black);

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final log = logs[group.x.toInt()];
              final realValue = (log['sleep'] ?? 0.0).toDouble();
              return BarTooltipItem(
                "${realValue.toStringAsFixed(1)} h",
                TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              interval: 2,
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) =>
                  value == 0 ? Text('0') : Text("${value.toInt()}"),
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
        gridData: FlGridData(show: true, horizontalInterval: 2),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(logs.length, (idx) {
          final value = logs[idx]['sleep'] ?? 0.0;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: value > maxY ? maxY : value,
                color: Colors.purple,
                width: 16,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
            showingTooltipIndicators: [],
          );
        }),
        groupsSpace: 18,
      ),
    );
  }
}
