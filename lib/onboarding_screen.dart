import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({Key? key, required this.onFinish}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  int age = 25;
  double height = 170, weight = 70, bodyFat = 18;
  double targetCalories = 2000, targetWater = 2.0, targetSleep = 8;
  bool loading = false;

  Future<void> _saveProfile() async {
    setState(() { loading = true; });
    User? user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'age': age,
      'height': height,
      'weight': weight,
      'bodyFat': bodyFat,
      'targetCalories': targetCalories,
      'targetWater': targetWater,
      'targetSleep': targetSleep,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    setState(() { loading = false; });
    widget.onFinish();
  }

  Widget _slider(String label, double value, double min, double max, Function(double) onChanged, {String? unit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}${unit ?? ""}', style: TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max-min).toInt(),
          label: value.toStringAsFixed(1),
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Let's Set Up Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Personal Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: "Age"),
                initialValue: age.toString(),
                keyboardType: TextInputType.number,
                validator: (v) => v != null && int.tryParse(v) != null ? null : "Enter valid age",
                onChanged: (v) => setState(() => age = int.tryParse(v) ?? age),
              ),
              _slider("Height", height, 120, 220, (v) => height = v, unit: " cm"),
              _slider("Weight", weight, 30, 200, (v) => weight = v, unit: " kg"),
              _slider("Body Fat %", bodyFat, 5, 45, (v) => bodyFat = v, unit: "%"),
              Divider(height: 36),
              Text("Your Targets", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _slider("Target Calories", targetCalories, 800, 4000, (v) => targetCalories = v, unit: " kcal"),
              _slider("Target Water", targetWater, 0.5, 6, (v) => targetWater = v, unit: " L"),
              _slider("Target Sleep", targetSleep, 4, 12, (v) => targetSleep = v, unit: " hrs"),
              SizedBox(height: 32),
              loading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) _saveProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Save & Continue", style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
