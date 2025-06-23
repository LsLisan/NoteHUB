import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
// Assuming these pages exist in your project
import 'package:notehub/pages/intro/postANote.dart';
import 'package:notehub/pages/manu.dart';
import 'package:notehub/pages/newsFeeds.dart';
import 'package:notehub/pages/notification.dart';

class UsersHomePage extends StatefulWidget {
  const UsersHomePage({super.key});

  @override
  State<UsersHomePage> createState() => _UsersHomePageState();
}

class _UsersHomePageState extends State<UsersHomePage> {
  int _currentIndex = 0;

  // List of pages to be displayed when a navigation item is tapped
  final List<Widget> _pages = [
    NewsFeedPage(),
    PostANotePage(),
    NotificationPage(),
    MenuPage(),
  ];

  // Helper function to determine the alignment of the animated hover indicator
  // based on the currently selected index.
  double _getAlignX(int index) {
    switch (index) {
      case 0:
        return -1.0; // Far left (Home)
      case 1:
        return -0.33; // Second from left (Post)
      case 2:
        return 0.33; // Second from right (Notifications)
      case 3:
        return 1.0; // Far right (Menu)
      default:
        return -1.0; // Default to home position
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Extends the body under the bottom navigation bar,
      // allowing content to show through the transparent bar, crucial for Liquid Glass.
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), // Smooth page transition
        child: _pages[_currentIndex], // Display the current page
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Sharpened corners
          child: BackdropFilter(
            // The core of the "Liquid Glass" effect.
            // Blurs the content behind this widget to create depth and refraction.
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28), // Further increased blur for more liquid glass
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                // Slightly more opaque white tint for a shinier, more pronounced glass feel.
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20), // Sharpened corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03), // Very soft shadow for subtle lift
                    blurRadius: 5, // Reduced blur radius for the shadow
                    offset: const Offset(0, 2), // Smaller offset for a floating look
                  ),
                ],
                // Add a subtle shining border
                border: Border.all(
                  color: Colors.white.withOpacity(0.3), // A subtle white border
                  width: 1.0, // Border thickness
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated hover indicator for the selected item.
                  // This also has a subtle blur effect, enhancing the glass look.
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutExpo, // Smooth animation curve
                    alignment: Alignment(_getAlignX(_currentIndex), 0),
                    child: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        // Clearer transparent white for the hover effect, giving it a "shiny" highlight.
                        color: Colors.deepOrange.withOpacity(0.20), // More prominent hover highlight
                      ),
                      child: BackdropFilter(
                        // Blur for the hover indicator
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Slightly increased blur for hover
                        child: const SizedBox(), // Placeholder for the blur effect
                      ),
                    ),
                  ),
                  BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index; // Update the selected index
                      });
                    },
                    type: BottomNavigationBarType.fixed, // Fixed items layout
                    backgroundColor: Colors.transparent, // Important for transparency
                    elevation: 0, // No default shadow from the bar itself
                    selectedItemColor: colorScheme.primary, // Color for selected icon
                    unselectedItemColor:
                    colorScheme.onSurface.withOpacity(0.6), // Color for unselected icons
                    showSelectedLabels: false, // Hide labels for selected items
                    showUnselectedLabels: false, // Hide labels for unselected items
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded),
                        label: 'Feed',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.add_circle_outline_rounded),
                        label: 'Post',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.notifications_rounded),
                        label: 'Notifications',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.menu_rounded),
                        label: 'Menu',
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
}
