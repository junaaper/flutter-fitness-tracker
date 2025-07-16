import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'sleep_log_screen.dart';
import 'workout_log_screen.dart';
import 'calorie_log_screen.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({Key? key}) : super(key: key);
  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int _index = 0;
  final pages = [
    DashboardScreen(),
    SleepLogScreen(),
    WorkoutLogScreen(),
    CalorieLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.nightlight_round), label: "Sleep"),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: "Workout"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_drink), label: "Nutrition"),
        ],
      ),
    );
  }
}
