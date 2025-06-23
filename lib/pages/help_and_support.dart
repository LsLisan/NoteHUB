import 'package:flutter/material.dart';
import 'package:notehub/pages/appSettings/settings.dart';
import 'package:notehub/pages/profiles/editProfile.dart';
import 'package:notehub/theames/app_color.dart';

class HelpAndSupportPage extends StatelessWidget {
  const HelpAndSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support', style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Title
            Text(
              'How can we assist you?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),

            // FAQ Section
            _buildSection(
              title: 'Frequently Asked Questions (FAQs)',
              content: [
                _buildFAQItem('How do I reset my password?', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfileEditPage()));
                }),
                _buildFAQItem('How can I change my phone number?', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfileEditPage()));
                }),
                _buildFAQItem('How can I enable dark mode?', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context)=>SettingsPage()));
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Contact Support Section
            _buildSection(
              title: 'Contact Support',
              content: [
                ListTile(
                  leading: Icon(Icons.email, color: colorScheme.primary),
                  title: Text('Email Support'),
                  subtitle: Text('support@notehub.com'),
                  onTap: () {
                    // Launch email client or open contact form
                  },
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: colorScheme.primary),
                  title: Text('Phone Support'),
                  subtitle: Text('1-800-123-4567'),
                  onTap: () {
                    // Call support number
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Help Center Section
            _buildSection(
              title: 'Help Center & Documentation',
              content: [
                ListTile(
                  leading: Icon(Icons.help_outline, color: colorScheme.primary),
                  title: Text('Visit Help Center'),
                  onTap: () {
                    // Open the help center or FAQ page
                  },
                ),
                ListTile(
                  leading: Icon(Icons.book, color: colorScheme.primary),
                  title: Text('User Guide & Documentation'),
                  onTap: () {
                    // Open user guide or documentation link
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...content,
      ],
    );
  }

  Widget _buildFAQItem(String question, VoidCallback onTap) {
    return ListTile(
      leading: Icon(Icons.question_answer, color: Colors.orange),
      title: Text(question),
      onTap: onTap,
    );
  }
}
