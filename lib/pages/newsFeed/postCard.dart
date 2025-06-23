import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notehub/interactions/comments.dart';
import 'package:notehub/interactions/likes.dart';
import 'package:notehub/pages/newsFeed/reportService.dart';
import 'package:notehub/pages/newsFeed/timeFormater.dart';
import 'package:notehub/pages/profiles/profileScreen.dart';
import 'package:notehub/pages/viewPostPage.dart'; // Import the new page

class PostCard extends StatelessWidget {
  final DocumentSnapshot post;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReportService _reportService = ReportService();

  PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postData = post.data() as Map<String, dynamic>;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(postData['uid']).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: Colors.orange)),
            ),
          );
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final timestamp = postData['timestamp'] as Timestamp;
        final postDate = timestamp.toDate();
        final timeAgo = TimeFormatter.getTimeAgo(postDate);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: InkWell(
            // Add this InkWell to make the entire card clickable
            onTap: () {
              // Navigate to the ViewPostPage when the post is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewPostPage(postID: post.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoRow(context, userData, timeAgo, theme),
                  const Divider(height: 24),
                  _buildPostContent(postData, theme, context), // Pass context to navigate
                  const SizedBox(height: 12),
                  _buildInteractionButtons(context, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfoRow(BuildContext context, Map<String, dynamic> userData, String timeAgo, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.orange[200],
          child: InkWell(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userUID: post['uid'])),
                );
            },
            child: Text(
              (userData['nickname'] ?? 'A')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userData['nickname'] ?? 'Anonymous',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              timeAgo,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ),
        const Spacer(),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.hintColor),
          onSelected: (value) {
            if (value == 'report') {
              _reportService.reportPost(context, post.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Report'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostContent(Map<String, dynamic> postData, ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title of the post
        Text(
          postData['title'] ?? 'No Title',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Post subject
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: Text(
            postData['subject'] ?? 'No Subject',
            style: TextStyle(color: Colors.orange[800], fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Post description (preview)
        Text(
          _getPreviewText(postData['description']),
          style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
        ),
        const SizedBox(height: 6),

        // Read more button if needed
        if ((postData['description'] ?? '').toString().split(' ').length > 50)
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 20),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              // Navigate to ViewPostPage instead of implementing read more functionality here
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewPostPage(postID: post.id),
                ),
              );
            },
            child: Text(
              'Read more',
              style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractionButtons(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Like button
        LikeButton(
          postID: post.id,
          userID: _auth.currentUser!.uid,
        ),
        const SizedBox(width: 16),

        // Comment button
        InkWell(
          onTap: () {
            // Navigate to the ViewPostPage and focus on comments section
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewPostPage(postID: post.id),
              ),
            );
          },
          child: Row(
            children: [
              Icon(Icons.comment_outlined, size: 18, color: theme.hintColor),
              const SizedBox(width: 4),
              Text(
                'Comment',
                style: TextStyle(color: theme.hintColor),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Save/bookmark button
        IconButton(
          icon: Icon(Icons.bookmark_border, color: theme.hintColor),
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              final uid = user.uid;

              final postData = post.data() as Map<String, dynamic>;

              final bookmarkedItem = {
                'postID': post.id,
                'title': postData['title'] ?? '',
                'subject': postData['subject'] ?? '',
                'authorUID': postData['uid'],
                'timestamp': Timestamp.now(),
              };

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('bookmarks')
                    .doc(post.id) // Optional: use post ID to prevent duplicates
                    .set(bookmarkedItem);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Post bookmarked!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error bookmarking post: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to bookmark post.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              print('User not signed in');
            }
          },
        )

      ],
    );
  }

  String _getPreviewText(dynamic description) {
    if (description == null) return 'No description provided';

    final words = description.toString().split(' ');
    if (words.length <= 50) return description.toString();

    return words.take(50).join(' ') + '...';
  }
}