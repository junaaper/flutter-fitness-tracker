import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'selected_date_notifier.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final selectedDate = context.watch<SelectedDateNotifier>().selected;
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final dateKey =
        "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data();
          final userMap = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
          final targetCalories = (userMap['targetCalories'] ?? 2000).toDouble();
          final targetWater = (userMap['targetWater'] ?? 2.5).toDouble();
          final targetSleep = (userMap['targetSleep'] ?? 8.0).toDouble();
          final weight = (userMap['weight'] ?? 70).toDouble();
          final height = (userMap['height'] ?? 170).toDouble();

          double bmi = 0;
          String bmiStatus = '';
          Color bmiColor = Colors.blue;

          if (weight > 0 && height > 0) {
            bmi = weight / pow(height / 100, 2);
            if (bmi < 18.5) {
              bmiStatus = "Underweight";
              bmiColor = Colors.orange;
            } else if (bmi < 25) {
              bmiStatus = "Healthy";
              bmiColor = Colors.green;
            } else if (bmi < 30) {
              bmiStatus = "Overweight";
              bmiColor = Colors.amber;
            } else {
              bmiStatus = "Obese";
              bmiColor = Colors.red;
            }
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('logs')
                .doc(dateKey)
                .get(),
            builder: (context, snap) {
              if (!snap.hasData)
                return Center(child: CircularProgressIndicator());
              final logRaw = snap.data?.data();
              final log = logRaw is Map
                  ? Map<String, dynamic>.from(logRaw)
                  : <String, dynamic>{};
              final calories = (log['calories'] ?? 0).toDouble();
              final water = (log['water'] ?? 0).toDouble();
              final sleep = (log['sleep'] ?? 0).toDouble();

              final w = MediaQuery.of(context).size.width;
              final h = MediaQuery.of(context).size.height;
              final radius = min((w - 64) / 4, 80.0);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 20, color: Colors.blue[400]),
                        SizedBox(width: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            textStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          child: Text(
                            isToday
                                ? "Today"
                                : "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2022),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              context.read<SelectedDateNotifier>().setDate(picked);
                            }
                          },
                        ),
                        if (!isToday)
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 20, color: Colors.red[400]),
                            tooltip: "Back to Today",
                            onPressed: () =>
                                context.read<SelectedDateNotifier>().resetToToday(),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 32, top: 16),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                          child: IntrinsicHeight(
                            child: Wrap(
                              spacing: 24,
                              runSpacing: 28,
                              alignment: WrapAlignment.center,
                              runAlignment: WrapAlignment.center,
                              children: [
                                _CircleProgress(
                                  title: "Calories",
                                  value: calories,
                                  goal: targetCalories,
                                  color: Colors.orange,
                                  unit: "kcal",
                                  status: calories >= targetCalories
                                      ? "Goal met!"
                                      : "Goal not met",
                                  statusColor: calories >= targetCalories
                                      ? Colors.green
                                      : Colors.red,
                                  radius: radius,
                                ),
                                _CircleProgress(
                                  title: "Water",
                                  value: water,
                                  goal: targetWater,
                                  color: Colors.blue,
                                  unit: "L",
                                  status: water >= targetWater
                                      ? "Goal met!"
                                      : "Goal not met",
                                  statusColor: water >= targetWater
                                      ? Colors.green
                                      : Colors.red,
                                  radius: radius,
                                ),
                                _CircleProgress(
                                  title: "Sleep",
                                  value: sleep,
                                  goal: targetSleep,
                                  color: Colors.purple[300]!,
                                  unit: "h",
                                  status: sleep >= targetSleep ? "Good" : "Poor",
                                  statusColor:
                                      sleep >= targetSleep ? Colors.green : Colors.red,
                                  radius: radius,
                                ),
                                _BMICircle(
                                  bmi: bmi,
                                  status: bmiStatus,
                                  color: bmiColor,
                                  radius: radius,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CircleProgress extends StatelessWidget {
  final String title, unit, status;
  final double value, goal, radius;
  final Color color, statusColor;
  const _CircleProgress({
    required this.title,
    required this.value,
    required this.goal,
    required this.color,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    double percent = (goal == 0) ? 0 : (value / goal).clamp(0.0, 1.0);
    return SizedBox(
      width: radius * 2 + 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: radius,
            lineWidth: 13,
            percent: percent,
            center: Container(
              width: radius * 1.4,
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "${_shortNumber(value)}/${_shortNumber(goal)}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: radius * 0.38),
                  maxLines: 1,
                ),
              ),
            ),
            progressColor: color,
            backgroundColor: color.withOpacity(0.15),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: statusColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _BMICircle extends StatelessWidget {
  final double bmi;
  final String status;
  final Color color;
  final double radius;

  const _BMICircle({
    required this.bmi,
    required this.status,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2 + 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: radius,
            lineWidth: 13,
            percent: (bmi / 40.0).clamp(0.0, 1.0),
            center: Container(
              width: radius * 1.4,
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  bmi == 0 ? "--" : bmi.toStringAsFixed(1),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: radius * 0.38),
                  maxLines: 1,
                ),
              ),
            ),
            progressColor: color,
            backgroundColor: color.withOpacity(0.18),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          SizedBox(height: 10),
          Text("BMI", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

String _shortNumber(double n) {
  if (n >= 10000)
    return n.toStringAsFixed(0);
  else if (n >= 1000)
    return n.toStringAsFixed(0);
  else if (n == n.roundToDouble())
    return n.toStringAsFixed(0);
  else
    return n.toStringAsFixed(1);
}
