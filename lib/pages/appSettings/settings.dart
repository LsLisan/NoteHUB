import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:notehub/theames/theme_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = context.read<ThemeCubit>().state == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.orange,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                _isDarkMode ? Icons.nightlight_round :Icons.sunny , // Change icon based on theme
                color: colorScheme.primary,
              ),
              title: Text(_isDarkMode ? 'Dark Mode':'Light Mode', style: TextStyle(fontSize: 18)),
              trailing: Switch(
                value: _isDarkMode,
                activeColor: colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  // Update the theme in ThemeCubit
                  context.read<ThemeCubit>().updateTheme(
                    _isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            ).animate().fade(duration: 600.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: 500.ms,
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toggle Dark Mode to change the app\'s theme.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 700.ms).slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }
}
