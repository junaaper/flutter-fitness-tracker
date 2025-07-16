import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _formKey = GlobalKey<FormState>();

  final _fields = {
    "height": TextEditingController(),
    "weight": TextEditingController(),
    "age": TextEditingController(),
    "bodyFat": TextEditingController(),
    "targetCalories": TextEditingController(),
    "targetWater": TextEditingController(),
    "targetSleep": TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    _fields["height"]!.text = (data['height'] ?? '').toString();
    _fields["weight"]!.text = (data['weight'] ?? '').toString();
    _fields["age"]!.text = (data['age'] ?? '').toString();
    _fields["bodyFat"]!.text = (data['bodyFat'] ?? '').toString();
    _fields["targetCalories"]!.text = (data['targetCalories'] ?? '').toString();
    _fields["targetWater"]!.text = (data['targetWater'] ?? '').toString();
    _fields["targetSleep"]!.text = (data['targetSleep'] ?? '').toString();
    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'height': double.tryParse(_fields["height"]!.text) ?? 0.0,
      'weight': double.tryParse(_fields["weight"]!.text) ?? 0.0,
      'age': int.tryParse(_fields["age"]!.text) ?? 0,
      'bodyFat': double.tryParse(_fields["bodyFat"]!.text) ?? 0.0,
      'targetCalories': double.tryParse(_fields["targetCalories"]!.text) ?? 0.0,
      'targetWater': double.tryParse(_fields["targetWater"]!.text) ?? 0.0,
      'targetSleep': double.tryParse(_fields["targetSleep"]!.text) ?? 0.0,
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile Saved!")));
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Log Out"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Log Out", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red[300]),
            onPressed: _confirmLogout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              width: constraints.maxWidth < 500 ? double.infinity : 420,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _profileInput(_fields["height"]!, "Height (cm)"),
                    spacing,
                    _profileInput(_fields["weight"]!, "Weight (kg)"),
                    spacing,
                    _profileInput(_fields["age"]!, "Age", isInt: true),
                    spacing,
                    _profileInput(_fields["bodyFat"]!, "Body Fat %"),
                    spacing,
                    Divider(),
                    spacing,
                    _profileInput(_fields["targetCalories"]!, "Target Calories (kcal)"),
                    spacing,
                    _profileInput(_fields["targetWater"]!, "Target Water (L)"),
                    spacing,
                    _profileInput(_fields["targetSleep"]!, "Target Sleep (h)"),
                    spacing,
                    SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        minimumSize: Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      onPressed: _saveProfile,
                      child: Text(
                        "Save",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileInput(TextEditingController c, String label, {bool isInt = false}) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
      style: TextStyle(fontSize: 17),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: TextStyle(fontWeight: FontWeight.w500, color: Colors.indigo),
      ),
    );
  }
}
