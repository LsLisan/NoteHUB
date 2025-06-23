import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notehub/interactions/comments.dart';
import 'package:notehub/interactions/likes.dart';
import 'package:notehub/pages/newsFeed/reportService.dart';
import 'package:notehub/pages/newsFeed/timeFormater.dart';
import 'package:notehub/pages/profiles/profileScreen.dart';
import 'package:notehub/theames/app_color.dart';

class ViewPostPage extends StatefulWidget {
  final String postID;

  const ViewPostPage({super.key, required this.postID});

  @override
  State<ViewPostPage> createState() => _ViewPostPageState();
}

class _ViewPostPageState extends State<ViewPostPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  bool _hasError = false;
  DocumentSnapshot? _postData;
  DocumentSnapshot? _userData;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch post data
      final postDoc = await _firestore.collection('posts').doc(widget.postID).get();

      if (!postDoc.exists) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      // Fetch user data (author)
      final postData = postDoc.data() as Map<String, dynamic>;
      final userDoc = await _firestore.collection('users').doc(postData['uid']).get();

      setState(() {
        _postData = postDoc;
        _userData = userDoc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post Details',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          if (_postData != null)
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.black87),
              onPressed: () {
                // Implement save/bookmark functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post saved to bookmarks')),
                );
              },
            ),
          if (_postData != null)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black87),
              onPressed: () {
                // Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing post...')),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _hasError
          ? _buildErrorState(theme)
          : _buildPostDetails(theme),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Could not load post',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadPostData,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostDetails(ThemeData theme) {
    final postData = _postData!.data() as Map<String, dynamic>;
    final userData = _userData!.data() as Map<String, dynamic>;
    final timestamp = postData['timestamp'] as Timestamp;
    final postUserUID = postData['uid'];
    final postDate = timestamp.toDate();
    final timeAgo = TimeFormatter.getTimeAgo(postDate);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info section
          _buildUserInfoSection(userData, timeAgo, theme,postDate,postUserUID),

          // Divider
          const Divider(height: 1),

          // Post content section
          _buildPostContentSection(postData, theme),

          // Stats section (likes, views)
          _buildStatsSection(theme),

          // Divider
          const Divider(height: 1),

          // Interaction buttons
          _buildInteractionButtons(theme),

          // Divider
          const Divider(height: 1),

          // Comments section
          _buildCommentsSection(theme),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(Map<String, dynamic> userData, String timeAgo, ThemeData theme,postData,postUserUID) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          InkWell(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userUID: postUserUID),
                ),
              );
            },
            child: CircleAvatar(
              backgroundColor: Colors.orange[300],
              radius: 24,
              child: InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(userUID: postUserUID),
                    ),
                  );
                },
                child: Text(
                  (userData['nickname'] ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['nickname'] ?? 'Anonymous',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.hintColor),
            onSelected: (value) {
              if (value == 'report') {
                _reportService.reportPost(context, widget.postID);
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
      ),
    );
  }

  Widget _buildPostContentSection(Map<String, dynamic> postData, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title of the post
          Text(
            postData['title'] ?? 'No Title',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Post subject/topic tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Text(
              postData['subject'] ?? 'No Subject',
              style: TextStyle(color: Colors.orange[800], fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Post full description
          Text(
            postData['description'] ?? 'No description provided',
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),

          // Show attached files if any
          if (postData['attachments'] != null && (postData['attachments'] as List).isNotEmpty)
            _buildAttachmentSection(postData['attachments'], theme),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection(List attachments, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Attachments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.orange),
                title: Text(attachment['name'] ?? 'File ${index + 1}'),
                subtitle: Text(attachment['type'] ?? 'Unknown type'),
                trailing: const Icon(Icons.download_outlined),
                onTap: () {
                  // Handle attachment download or preview
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading attachment...')),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('posts').doc(widget.postID).collection('likes').snapshots(),
            builder: (context, snapshot) {
              int likeCount = 0;
              if (snapshot.hasData) {
                likeCount = snapshot.data!.docs.length;
              }
              return Text(
                '$likeCount likes',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              );
            },
          ),
          const SizedBox(width: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('posts').doc(widget.postID).collection('comments').snapshots(),
            builder: (context, snapshot) {
              int commentCount = 0;
              if (snapshot.hasData) {
                commentCount = snapshot.data!.docs.length;
              }
              return Text(
                '$commentCount comments',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Like button
          LikeButton(
            postID: widget.postID,
            userID: _auth.currentUser!.uid,
          ),

          // Comment button
          InkWell(
            onTap: () {
              // Focus comment section
              // You could use a scroll controller to scroll to comments
            },
            child: Row(
              children: [
                Icon(Icons.comment_outlined, size: 20, color: theme.hintColor),
                const SizedBox(width: 8),
                Text(
                  'Comment',
                  style: TextStyle(color: theme.hintColor),
                ),
              ],
            ),
          ),

          // Share button
          InkWell(
            onTap: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing post...')),
              );
            },
            child: Row(
              children: [
                Icon(Icons.share_outlined, size: 20, color: theme.hintColor),
                const SizedBox(width: 8),
                Text(
                  'Share',
                  style: TextStyle(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Comments list
          CommentSection(
            noteID: widget.postID,
            currentUserID: _auth.currentUser!.uid,
          ),
        ],
      ),
    );
  }
}