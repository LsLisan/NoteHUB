import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:notehub/pages/forget_password.dart';
import 'package:notehub/pages/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notehub/pages/usersHomepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.orange);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome\n     To\nNoteHUB ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ).animate().fade(duration: 600.ms).moveY(begin: -20, end: 0),
                  const SizedBox(height: 40),
                  _buildTextField(_emailController, 'Email', Icons.email, colorScheme: colorScheme),
                  const SizedBox(height: 20),
                  _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true, colorScheme: colorScheme),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ForgetPasswordPage()));
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildLoginButton(colorScheme),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (Context) => SignupPage())
                          );
                        },
                        child: Text('Sign Up', style: TextStyle(color: colorScheme.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, required ColorScheme colorScheme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: AnimatedContainer(
        duration: 500.ms,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          obscureText: isPassword ? !_isPasswordVisible : false,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            hintText: label,
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: colorScheme.primary),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            )
                : null,
          ),
        ),
      ).animate().fade(duration: 800.ms).moveX(begin: -50, end: 0),
    );
  }

  Widget _buildLoginButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _login,
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Login',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ).animate().scale(duration: 400.ms, begin: Offset(0.8, 0.8), end: Offset(1, 1)).then().shake(duration: 300.ms),
      ),
    );
  }

  void _login() async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Successful login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Text('Login successful!'),
        ),
      );
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context)=>UsersHomePage())
      );
      // Navigate to home or dashboard page after login
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text('Login failed. Please try again.'),
        ),
      );
    }
  }
}
