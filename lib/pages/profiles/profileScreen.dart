import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notehub/pages/newsFeed/timeFormater.dart';
import 'package:notehub/pages/profiles/editPostPage.dart';
import 'package:notehub/pages/viewPostPage.dart';

class ProfilePage extends StatefulWidget {
  final String userUID;
  final bool isCurrentUser;

  const ProfilePage({
    Key? key,
    required this.userUID,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User data
  Map<String, dynamic>? userData;
  bool _isLoadingUser = true;

  // Posts data
  List<DocumentSnapshot> _posts = [];
  bool _isLoadingPosts = true;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;
  final int _postLimit = 5; // Reduced from 10 to 5 for initial load

  // Stats
  int _postCount = 0;
  int _totalLikes = 0;
  bool _isLoadingStats = true;

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Load data with some delay to prevent UI freezes
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialData() async {
    // Load user data first
    await _loadUserData();

    // Then load initial posts
    await _loadInitialPosts();

    // Load stats after posts are loaded
    _loadUserStats();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userUID).get();

      if (mounted) {
        setState(() {
          userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _loadInitialPosts() async {
    if (!mounted) return;

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('posts')
          .where('uid', isEqualTo: widget.userUID)
          .orderBy('timestamp', descending: true)
          .limit(_postLimit)
          .get();

      if (mounted) {
        setState(() {
          _posts = querySnapshot.docs;
          _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
          _hasMorePosts = querySnapshot.docs.length >= _postLimit;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts || _lastDocument == null || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('posts')
          .where('uid', isEqualTo: widget.userUID)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postLimit)
          .get();

      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _posts.addAll(querySnapshot.docs);
            _lastDocument = querySnapshot.docs.last;
          }
          _hasMorePosts = querySnapshot.docs.length >= _postLimit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadUserStats() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Get total post count efficiently
      final postCountQuery = await _firestore
          .collection('posts')
          .where('uid', isEqualTo: widget.userUID)
          .count()
          .get();

      int postCount = postCountQuery.count ?? 0;

      // Get total likes more efficiently using aggregation
      int totalLikes = 0;

      // Fetch posts in smaller batches to calculate likes
      if (postCount > 0) {
        // Use a more efficient approach for likes calculation
        final batch1Query = await _firestore
            .collection('posts')
            .where('uid', isEqualTo: widget.userUID)
            .orderBy('timestamp', descending: true)
            .limit(50) // Limit batch size
            .get();

        List<Future<AggregateQuerySnapshot>> likeFutures = [];

        for (var doc in batch1Query.docs) {
          likeFutures.add(_firestore
              .collection('posts')
              .doc(doc.id)
              .collection('likes')
              .count()
              .get());
        }

        final likeResults = await Future.wait(likeFutures);

        for (var result in likeResults) {
          totalLikes += result.count ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          _postCount = postCount;
          _totalLikes = totalLikes;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  // Navigate to edit post page
  Future<void> _navigateToEditPost(String postId, String postOwnerId) async {
    // Check if current user is the post owner
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to edit posts')),
      );
      return;
    }

    if (currentUser.uid != postOwnerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit this post')),
      );
      return;
    }

    // If user is authorized, navigate to edit post page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostPage(postID: postId),
      ),
    );

    // If post was updated, refresh the posts list
    if (result == true) {
      _refreshAllData();
    }
  }

  Future<void> _deletePost(String postId, String postOwnerId) async {
    // Check if current user is the post owner
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to delete posts')),
      );
      return;
    }

    if (currentUser.uid != postOwnerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to delete this post')),
      );
      return;
    }

    try {
      // Show confirmation dialog
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (!confirmDelete) return;

      // Delete post document
      await _firestore.collection('posts').doc(postId).delete();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }

      // Refresh posts and stats
      _refreshAllData();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete post. Please try again.')),
        );
      }
    }
  }

  Future<void> _refreshAllData() async {
    if (!mounted) return;

    setState(() {
      _posts = [];
      _lastDocument = null;
      _hasMorePosts = true;
      _isLoadingPosts = true;
      _isLoadingStats = true;
    });

    await _loadInitialPosts();
    _loadUserStats();
  }

  bool _canModifyPost(String postOwnerId) {
    User? currentUser = _auth.currentUser;
    return currentUser != null && currentUser.uid == postOwnerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCurrentUser ? 'My Profile' : 'User Profile'),
        centerTitle: true,
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
        onRefresh: _refreshAllData,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildUserStats(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Posts',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _isLoadingPosts
                ? SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
            )
                : _posts.isEmpty
                ? SliverToBoxAdapter(
              child: _buildEmptyPostsMessage(),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index < _posts.length) {
                    return _buildPostCard(_posts[index]);
                  } else if (_isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    );
                  } else {
                    return const SizedBox(height: 50); // Footer space
                  }
                },
                childCount: _posts.length + (_isLoadingMore ? 1 : 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPostsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.post_add,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.isCurrentUser
                  ? 'You haven\'t posted anything yet'
                  : 'This user hasn\'t posted anything yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (userData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('User not found'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Hero(
            tag: 'profile-${widget.userUID}',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange[200],
              child: Text(
                (userData!['nickname'] ?? 'A')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userData!['fullName'] ?? 'Anonymous',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (userData!['bio'] != null && userData!['bio'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                userData!['bio'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ),
          if (widget.isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile functionality will be implemented soon')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[50],
                  foregroundColor: Colors.orange[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.orange[200]!),
                  ),
                ),
                child: const Text('Edit Profile'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: _isLoadingStats
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          ),
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Posts', _postCount.toString()),
          _buildStatItem('Likes', _totalLikes.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot post) {
    final postData = post.data() as Map<String, dynamic>;
    final timestamp = postData['timestamp'] as Timestamp;
    final postDate = timestamp.toDate();
    final timeAgo = TimeFormatter.getTimeAgo(postDate);
    final postOwnerId = postData['uid'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewPostPage(postID: post.id),
            ),
          ).then((_) {
            // Only refresh stats after viewing post to reduce load
            if (mounted) _loadUserStats();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(timeAgo, post.id, postOwnerId),
              const Divider(height: 24),
              _buildPostContent(postData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(String timeAgo, String postId, String postOwnerId) {
    final canModify = _canModifyPost(postOwnerId);

    return Row(
      children: [
        Text(
          timeAgo,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
        const Spacer(),
        if (canModify)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Theme.of(context).hintColor),
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEditPost(postId, postOwnerId);
              } else if (value == 'delete') {
                _deletePost(postId, postOwnerId);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Post'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Post', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPostContent(Map<String, dynamic> postData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          postData['title'] ?? 'No Title',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
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
        Text(
          _getPreviewText(postData['description']),
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getPreviewText(dynamic description) {
    if (description == null) return 'No description provided';
    return description.toString();
  }
}