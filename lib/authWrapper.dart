import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notehub/pages/login.dart';
import 'package:notehub/pages/splash.dart';
import 'package:notehub/pages/usersHomepage.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          // User is signed in
          return const UsersHomePage(); // Replace with your home screen
        } else {
          // User is not signed in
          return const SplashPage(); // Replace with your login screen
        }
      },
    );
  }
}
