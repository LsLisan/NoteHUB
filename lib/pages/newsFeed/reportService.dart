import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> reportPost(BuildContext context, String postId) async {
    final TextEditingController reportReasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for reporting this post:'),
              const SizedBox(height: 16),
              TextField(
                controller: reportReasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason here',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _submitReport(context, postId, reportReasonController.text);
              },
              child: const Text('Submit Report'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReport(BuildContext context, String postId, String reason) async {
    if (reason.trim().isNotEmpty) {
      // Submit report to Firestore
      await _firestore.collection('reports').add({
        'postUID': postId,
        'userUID': _auth.currentUser!.uid,
        'reason': reason.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Thank you for helping us maintain community standards.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show error if reason is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for the report.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}