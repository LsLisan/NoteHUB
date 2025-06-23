import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:notehub/pages/viewPostPage.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  _BookmarksPageState createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Stream<QuerySnapshot> _bookmarksStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeBookmarksStream();
  }

  void _initializeBookmarksStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _bookmarksStream = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .orderBy('timestamp', descending: true)
          .snapshots();

      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<DocumentSnapshot> _getUserData(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Future<void> _removeBookmark(String bookmarkId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('bookmarks')
            .doc(bookmarkId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed from bookmarks')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing bookmark: ${e.toString()}')),
      );
    }
  }

  void _navigateToPostDetails(String postId) {
    // Navigate to post details page
    // Replace PostDetailsPage with your actual post details page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPostPage(postID: postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _auth.currentUser == null
          ? const Center(child: Text('Please sign in to view bookmarks'))
          : StreamBuilder<QuerySnapshot>(
        stream: _bookmarksStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No bookmarks yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Posts you bookmark will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final bookmarkDoc = snapshot.data!.docs[index];
              final bookmarkData = bookmarkDoc.data() as Map<String, dynamic>;

              // Using the structure you provided
              final String postId = bookmarkData['postID'] ?? '';
              final String title = bookmarkData['title'] ?? '';
              final String subject = bookmarkData['subject'] ?? '';
              final String authorUID = bookmarkData['authorUID'] ?? '';
              final Timestamp timestamp = bookmarkData['timestamp'] ?? Timestamp.now();

              return FutureBuilder<DocumentSnapshot>(
                future: _getUserData(authorUID),
                builder: (context, authorSnapshot) {
                  String authorName = 'Unknown User';
                  String authorPhotoUrl = '';

                  if (authorSnapshot.hasData && authorSnapshot.data!.exists) {
                    final authorData = authorSnapshot.data!.data() as Map<String, dynamic>;
                    authorName = authorData['fullName'] ?? authorData['displayName'] ?? 'Unknown User';
                    authorPhotoUrl = authorData['photoUrl'] ?? authorData['photoURL'] ?? '';
                  }

                  return Dismissible(
                    key: Key(bookmarkDoc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Remove Bookmark"),
                            content: const Text("Are you sure you want to remove this post from your bookmarks?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text("Remove"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      _removeBookmark(bookmarkDoc.id);
                    },
                    child: InkWell(
                      onTap: () => _navigateToPostDetails(postId),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Info
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundImage: authorPhotoUrl.isNotEmpty
                                    ? NetworkImage(authorPhotoUrl)
                                    : null,
                                child: authorPhotoUrl.isEmpty
                                    ? Text(authorName[0].toUpperCase())
                                    : null,
                              ),
                              title: Text(
                                authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate()),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.bookmark, color: Colors.blue),
                                onPressed: () => _removeBookmark(bookmarkDoc.id),
                              ),
                            ),

                            // Post Title
                            if (title.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            // Post Subject
                            Padding(
                              padding: const EdgeInsets.all(16).copyWith(top: title.isNotEmpty ? 8 : 0),
                              child: Text(
                                subject,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Bookmark Time
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const Spacer(),
                                  Text(
                                    'Saved on ${DateFormat('MMM d').format(timestamp.toDate())}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}