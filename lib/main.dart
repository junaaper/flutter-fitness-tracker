import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'auth_screen.dart';
import 'onboarding_screen.dart';
import 'home_nav.dart';
import 'profile_screen.dart';
import 'selected_date_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectedDateNotifier(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitnestX',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          fontFamily: "Montserrat",
          scaffoldBackgroundColor: Color(0xFFF8F8FF),
          useMaterial3: true,
        ),
        routes: {
          '/profile': (_) => ProfileScreen(),
        },
        home: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? user;
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((u) {
      setState(() {
        user = u;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return AuthScreen(onLogin: (u) => setState(() => user = u));
    }
    return FutureBuilder(
      future: _hasProfile(user!),
      builder: (context, snap) {
        if (!snap.hasData) return Scaffold(body: Center(child: CircularProgressIndicator()));
        final hasProfile = snap.data as bool;
        if (!hasProfile) {
          return OnboardingScreen(onFinish: () => setState(() {}));
        }
        return HomeNav();
      },
    );
  }

  Future<bool> _hasProfile(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists;
  }
}
