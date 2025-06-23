import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notehub/pages/appSettings/settings.dart';
import 'package:notehub/pages/help_and_support.dart';
import 'package:notehub/pages/login.dart';
import 'package:notehub/pages/profiles/bookmarks.dart';
import 'package:notehub/pages/profiles/editProfile.dart';
import 'package:notehub/pages/profiles/profileScreen.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _username; // Stores the fetched username
  String? _userEmail; // Stores the fetched user email

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch username and email on initialization
  }

  // Fetches username and email from Firestore
  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _username = doc['nickname'] ?? 'User'; // Get nickname, default to 'User'
            _userEmail = user.email; // Get email from Firebase Auth user object
          });
        } else {
          setState(() {
            _username = 'New User'; // Handle case where user document doesn't exist
            _userEmail = user.email;
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _username = 'Error'; // Indicate an error occurred
          _userEmail = user.email;
        });
      }
    } else {
      // If user is not logged in, clear existing data
      setState(() {
        _username = null;
        _userEmail = null;
      });
    }
  }

  // Handles user logout
  Future<void> _logout() async {
    try {
      await _auth.signOut(); // Sign out from Firebase
      // Navigate to the login page and replace the current route stack
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error during logout: $e');
      // Optionally show a snackbar or alert for logout error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28, // Larger title like iOS
          ),
        ),
        centerTitle: false, // Align title to left for iOS feel
        backgroundColor: Colors.transparent, // Transparent app bar
        elevation: 0, // No shadow
        toolbarHeight: 80, // Taller app bar for space
      ),
      body: SafeArea( // Ensures content is not obscured by notches/status bars
        child: ListView( // Use ListView for scrollability and responsiveness
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Responsive horizontal padding
          children: [
            // User Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.08, // Responsive avatar size
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, size: screenWidth * 0.1, color: colorScheme.primary),
                  ),
                  SizedBox(width: screenWidth * 0.04), // Responsive spacing
                  Expanded( // Allows text to take available space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username ?? 'Loading...',
                          style: TextStyle(
                            fontSize: screenWidth * 0.055, // Responsive font size
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis, // Handle long names
                        ),
                        if (_userEmail != null) // Display email if available
                          Text(
                            _userEmail!,
                            style: TextStyle(
                              fontSize: screenWidth * 0.035, // Responsive font size
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.05), // Responsive spacing

            // Menu Items Section (Grouped visually)
            _buildSection([
              _buildMenuItem(context, 'My Profile', Icons.account_circle, () {
                final user = _auth.currentUser;
                if (user != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userUID: user.uid)));
                } else {
                  // Handle case where user is not logged in, maybe redirect to login or show a message
                  _showSnackBar('Please log in to view your profile.', Colors.orange);
                }
              }),
              _buildMenuItem(context, 'Edit Profile', Icons.edit, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditPage()));
              }),
              _buildMenuItem(context, 'Bookmarks', Icons.bookmark, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => BookmarksPage()));
              }),
            ], colorScheme),

            SizedBox(height: screenWidth * 0.04), // Spacing between sections

            _buildSection([
              _buildMenuItem(context, 'Settings', Icons.settings, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
              }),
              _buildMenuItem(context, 'Help & Support', Icons.help_outline, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HelpAndSupportPage()));
              }),
            ], colorScheme),

            SizedBox(height: screenWidth * 0.04), // Spacing before logout

            // Logout Button (Distinctive style)
            Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02), // Slight horizontal margin
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.2), // Light background
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _logout, // Call the logout function
                    highlightColor: Colors.red.withOpacity(0.1), // Red highlight for logout
                    splashColor: Colors.red.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red.shade700, size: 24), // Red icon
                              SizedBox(width: screenWidth * 0.04),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red.shade700, // Red text
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.red.shade700.withOpacity(0.7), // Subtle red chevron
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.08), // Space at bottom
          ],
        ),
      ),
    );
  }

  // Helper widget to build individual menu items
  Widget _buildMenuItem(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Material( // Provides InkWell splash effect
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            highlightColor: colorScheme.primary.withOpacity(0.08), // Subtle highlight on tap
            splashColor: colorScheme.primary.withOpacity(0.12), // Subtle splash on tap
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out icon/text and chevron
                children: [
                  Row(
                    children: [
                      Icon(icon, color: colorScheme.primary, size: 24), // Themed icon color
                      SizedBox(width: screenWidth * 0.04), // Responsive spacing
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045, // Responsive font size
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios, // iOS-style chevron
                    size: 18,
                    color: colorScheme.onSurface.withOpacity(0.7), // Subtle color
                  ),
                ],
              ),
            ),
          ),
        ),
        // Add a subtle divider below each item (except the last in a section)
        Divider(
          height: 1, // Thin divider
          indent: screenWidth * 0.12, // Indent to align with text
          endIndent: screenWidth * 0.02, // Small end indent
          color: colorScheme.onSurface.withOpacity(0.1), // Subtle color
        ),
      ],
    );
  }

  // Helper widget to group menu items into sections with rounded background
  Widget _buildSection(List<Widget> children, ColorScheme colorScheme) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02), // Slight horizontal margin
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.2), // Light background for the section
        borderRadius: BorderRadius.circular(12), // Rounded corners for the section
      ),
      child: ClipRRect( // Clip children to the rounded corners
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: children.map((item) {
            // Remove the last divider in a section to avoid double dividers
            if (item == children.last) {
              return item is Column && item.children.length > 1
                  ? Column(children: [item.children.first]) // Only return the item content without divider
                  : item;
            }
            return item;
          }).toList(),
        ),
      ),
    );
  }

  // Helper function to show a styled SnackBar (reused from PostANotePage)
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16,),
      ),
    );
  }
}