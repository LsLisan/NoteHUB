import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notehub/assets/app_images.dart';
import 'package:notehub/pages/login.dart';
import 'package:notehub/theames/theme_cubit.dart';

import '../../assets/basic_app_button.dart';
import '../../theames/app_color.dart';

class ChooseModePage extends StatelessWidget {
  ChooseModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppImages.notes_books),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Welcome",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text("Choose Mode", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: Color(0xff30393c).withOpacity(0.6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.dark_mode_outlined, color: Colors.white),
                                  onPressed: () {
                                    context.read<ThemeCubit>().updateTheme(ThemeMode.dark);
                                  },
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 60,
                            width: 60, // Adjust the width as needed
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle, // To make it rectangular with rounded corners
                              color: Color(0xff30393c).withOpacity(0.6), // Semi-transparent background
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.light_mode_outlined, color: Colors.white), // Icon inside the container
                                  onPressed: () {
                                    context.read<ThemeCubit>().updateTheme(ThemeMode.light);
                                  },
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      )
                      ,
                    ],
                  ),
                  SizedBox(height: 8),
                  BasicAppButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
                      );
                    },
                    title: "Continue",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
