import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theames/app_color.dart';

class LikeButton extends StatefulWidget {
  final String postID;
  final String userID;

  const LikeButton({super.key, required this.postID, required this.userID});

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _hasLiked = false;
  int _likeCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLikeState();
  }

  // Initialize like state
  Future<void> _initializeLikeState() async {
    setState(() => _isLoading = true);

    try {
      final hasLiked = await _checkIfUserLiked(widget.postID, widget.userID);
      final likeCount = await _getLikeCount(widget.postID);

      setState(() {
        _hasLiked = hasLiked;
        _likeCount = likeCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error initializing like state: $e');
    }
  }

  // Check if the user has liked
  Future<bool> _checkIfUserLiked(String postID, String userID) async {
    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .collection('likes')
          .doc(userID)
          .get();

      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking like: $e');
      return false;
    }
  }

  // Get the total like count
  Future<int> _getLikeCount(String postID) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .collection('likes')
          .get();

      return snapshot.size; // More efficient than snapshot.docs.length
    } catch (e) {
      debugPrint('Error getting like count: $e');
      return 0;
    }
  }

  // Toggle like
  Future<void> _toggleLike() async {
    setState(() => _isLoading = true);

    try {
      if (_hasLiked) {
        await _removeLike(widget.postID, widget.userID);
      } else {
        await _addLike(widget.postID, widget.userID);
      }
      await _initializeLikeState();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error toggling like: $e');
    }
  }

  // Add a like
  Future<void> _addLike(String postID, String userID) async {
    try {
      final likesRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .collection('likes');

      await likesRef.doc(userID).set({
        'userID': userID,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding like: $e');
    }
  }

  // Remove a like
  Future<void> _removeLike(String postID, String userID) async {
    try {
      final likesRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .collection('likes');

      await likesRef.doc(userID).delete();
    } catch (e) {
      debugPrint('Error removing like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _isLoading
            ? CircularProgressIndicator(color: AppColors.primary)
            : IconButton(
          icon: Icon(
            Icons.thumb_up,
            color: _hasLiked ? AppColors.primary : Colors.grey,
          ),
          onPressed: _toggleLike,
        ),
        const SizedBox(width: 8),
        _isLoading
            ? Container()
            : Text('$_likeCount Likes'),
      ],
    );
  }
}
