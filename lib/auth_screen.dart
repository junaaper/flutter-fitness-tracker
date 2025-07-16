import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  final void Function(User user) onLogin;
  const AuthScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  String? error;
  bool loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      UserCredential userCred;
      if (isLogin) {
        userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }
      widget.onLogin(userCred.user!);
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa2c4fd), Color(0xFFc9e0fc)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Title
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: "Fit JAM",
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                        TextSpan(
                            text: "X",
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.blue[600])),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text("Everybody Can Train",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.black54,
                      )),
                  SizedBox(height: 40),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                    color: Colors.white.withOpacity(0.96),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 26),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => isLogin = true),
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isLogin
                                          ? Colors.blue
                                          : Colors.grey,
                                      decoration: isLogin
                                          ? TextDecoration.underline
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 18),
                                GestureDetector(
                                  onTap: () => setState(() => isLogin = false),
                                  child: Text(
                                    "Register",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: !isLogin
                                          ? Colors.blue
                                          : Colors.grey,
                                      decoration: !isLogin
                                          ? TextDecoration.underline
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 22),
                            TextFormField(
                              decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: Icon(Icons.email_outlined)),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v != null && v.contains("@")
                                  ? null
                                  : "Enter a valid email",
                              onChanged: (v) => email = v,
                            ),
                            SizedBox(height: 14),
                            TextFormField(
                              decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: Icon(Icons.lock_outline)),
                              obscureText: true,
                              validator: (v) => v != null && v.length >= 6
                                  ? null
                                  : "Password too short",
                              onChanged: (v) => password = v,
                            ),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(error!,
                                    style: TextStyle(color: Colors.red)),
                              ),
                            SizedBox(height: 28),
                            loading
                                ? CircularProgressIndicator()
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16),
                                          backgroundColor: Colors.blue[400],
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28))),
                                      child: Text(
                                        isLogin ? "Login" : "Register",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: _submit,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
