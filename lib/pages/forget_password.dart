import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notehub/pages/login.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.orange);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ).animate().fade(duration: 600.ms).moveY(begin: -20, end: 0),
              const SizedBox(height: 40),
              _buildTextField(_emailController, 'Enter your Email', Icons.email, colorScheme),
              const SizedBox(height: 20),
              _buildResetButton(colorScheme),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                },
                child: Text(
                  'Back to Login',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, ColorScheme colorScheme) {
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
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            hintText: label,
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: colorScheme.primary),
          ),
        ),
      ).animate().fade(duration: 800.ms).moveX(begin: -50, end: 0),
    );
  }

  Widget _buildResetButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _resetPassword,
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
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
          'Send Reset Link',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ).animate().scale(duration: 400.ms, begin: Offset(0.8, 0.8), end: Offset(1, 1)).then().shake(duration: 300.ms),
      ),
    );
  }

  void _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Text('Password reset link sent to your email.'),
        ),
      );
      Navigator.pop(context); // Go back to LoginPage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text('Failed to send reset link. Please try again.'),
        ),
      );
    }
  }
}
