import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notehub/pages/login.dart';
import 'package:notehub/theames/app_color.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _selectedGender;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;



  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _fullNameController.text,
        'nickname': _nicknameController.text,
        'phone': _phoneController.text,
        'gender': _selectedGender,
        'email': _emailController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup successful!')),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.orange);

    return Scaffold(
      body: Container(
        child: Center(
          child: SingleChildScrollView(

            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pushReplacement(context, 
                        MaterialPageRoute(builder: (context)=>LoginPage())
                      ),
                    ),
                  ),
                  Text("Sign Up",style: TextStyle(color: AppColors.primary,fontSize: 32,fontWeight: FontWeight.bold),),
                  const SizedBox(height: 20),
                  _buildTextField(_fullNameController, 'Full Name', Icons.person, colorScheme:colorScheme),
                  const SizedBox(height: 20),
                  _buildTextField(_nicknameController, 'Nickname', Icons.person_outline, colorScheme:colorScheme),
                  const SizedBox(height: 20),
                  _buildTextField(_phoneController, 'Phone', Icons.phone, colorScheme:colorScheme),
                  const SizedBox(height: 20),
                  _buildGenderDropdown(colorScheme),
                  const SizedBox(height: 20),
                  _buildTextField(_emailController, 'Email', Icons.email, colorScheme:colorScheme),
                  const SizedBox(height: 20),
                  _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true, colorScheme: colorScheme),
                  const SizedBox(height: 20),
                  _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock, isPassword: true, colorScheme: colorScheme),
                  const SizedBox(height: 30),
                  _buildSignupButton(colorScheme),
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
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, required ColorScheme colorScheme}) {
    return AnimatedContainer(
      duration: 500.ms,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.3), // Increased opacity to make it darker
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
      ).animate().fade(duration: 800.ms).moveX(begin: -50, end: 0),
    );
  }


  Widget _buildGenderDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surface.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintText: 'Select Gender',
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      ),
      dropdownColor: colorScheme.surface,
      value: _selectedGender,
      items: ['Male', 'Female', 'Other']
          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
          .toList(),
      onChanged: (value) => setState(() => _selectedGender = value),
    );
  }

  Widget _buildSignupButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _signup,
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
          'Sign Up',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ).animate().scale(duration: 400.ms, begin: Offset(0.8, 0.8), end: Offset(1, 1)).then().shake(duration: 300.ms),
      ),

    );
  }
}
