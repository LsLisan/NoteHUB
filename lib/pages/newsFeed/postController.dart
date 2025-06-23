import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:notehub/pages/newsFeed/cpllapsableAppBar.dart';

class PostController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final int _postLimit = 10;

  // Last document for pagination
  DocumentSnapshot? _lastDocument;

  List<DocumentSnapshot> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadInitialPosts() async {
    await loadMorePosts();
  }

  Future<void> loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot;

      if (_posts.isEmpty) {
        querySnapshot = await _firestore
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .limit(_postLimit)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .startAfterDocument(_lastDocument!)
            .limit(_postLimit)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = querySnapshot.docs.last;
        _posts.addAll(querySnapshot.docs);
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPosts() async {
    _posts = [];
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();
    await loadMorePosts();
  }

  // Search functionality
  Future<void> searchPosts(String query, SearchType type) async {
    _posts = [];
    _lastDocument = null;
    _hasMore = true;
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot;
      String searchField;

      // Determine which field to search based on type
      switch (type) {
        case SearchType.title:
          searchField = 'title';
          break;
        case SearchType.topic:
          searchField = 'subject';
          break;
        case SearchType.username:
        // For username search, we need a different approach
          await _searchByUsername(query);
          return;
      }

      // For title and topic searches
      querySnapshot = await _firestore
          .collection('posts')
          .where(searchField, isGreaterThanOrEqualTo: query)
          .where(searchField, isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy(searchField)
          .limit(_postLimit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = querySnapshot.docs.last;
        _posts.addAll(querySnapshot.docs);
      }
    } catch (e) {
      debugPrint('Error searching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _searchByUsername(String username) async {
    try {
      // First, find users that match the username
      final userQuery = await _firestore
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: username)
          .where('nickname', isLessThanOrEqualTo: username + '\uf8ff')
          .get();

      if (userQuery.docs.isEmpty) {
        _hasMore = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get UIDs of matching users
      final userIds = userQuery.docs.map((doc) => doc.id).toList();

      // Then find posts by these users
      final postQuery = await _firestore
          .collection('posts')
          .where('uid', whereIn: userIds)
          .orderBy('timestamp', descending: true)
          .limit(_postLimit)
          .get();

      if (postQuery.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = postQuery.docs.last;
        _posts.addAll(postQuery.docs);
      }
    } catch (e) {
      debugPrint('Error searching by username: $e');
      // If "whereIn" fails due to too many userIds, fallback to simpler query
      if (e.toString().contains('maximum')) {
        await _fallbackUsernameSearch(username);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fallback method if there are too many userIds for a whereIn query
  Future<void> _fallbackUsernameSearch(String username) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return;
      }

      final userId = userQuery.docs.first.id;
      final postQuery = await _firestore
          .collection('posts')
          .where('uid', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(_postLimit)
          .get();

      if (postQuery.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = postQuery.docs.last;
        _posts.addAll(postQuery.docs);
      }
    } catch (e) {
      debugPrint('Error in fallback username search: $e');
    }
  }

  Future<void> loadMoreSearchResults(String query, SearchType type) async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot;

      // For username search
      if (type == SearchType.username) {
        await _loadMoreUsernamePosts(query);
        return;
      }

      // For title and topic searches
      String searchField = type == SearchType.title ? 'title' : 'subject';

      querySnapshot = await _firestore
          .collection('posts')
          .where(searchField, isGreaterThanOrEqualTo: query)
          .where(searchField, isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy(searchField)
          .startAfterDocument(_lastDocument!)
          .limit(_postLimit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = querySnapshot.docs.last;
        _posts.addAll(querySnapshot.docs);
      }
    } catch (e) {
      debugPrint('Error loading more search results: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMoreUsernamePosts(String username) async {
    try {
      // Get current user IDs from displayed posts
      final Set<String> currentUserIds = {};
      for (final post in _posts) {
        final data = post.data() as Map<String, dynamic>;
        currentUserIds.add(data['uid']);
      }

      // Find more users with this username who aren't already included
      final userQuery = await _firestore
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: username)
          .where('nickname', isLessThanOrEqualTo: username + '\uf8ff')
          .get();

      final moreUserIds = userQuery.docs
          .map((doc) => doc.id)
          .where((id) => !currentUserIds.contains(id))
          .toList();

      if (moreUserIds.isEmpty) {
        // If no new users, get more posts from existing users
        final postQuery = await _firestore
            .collection('posts')
            .where('uid', whereIn: currentUserIds.toList().take(10).toList())
            .orderBy('timestamp', descending: true)
            .startAfterDocument(_lastDocument!)
            .limit(_postLimit)
            .get();

        if (postQuery.docs.isEmpty) {
          _hasMore = false;
        } else {
          _lastDocument = postQuery.docs.last;
          _posts.addAll(postQuery.docs);
        }
      } else {
        // If new users found, get their posts
        final postQuery = await _firestore
            .collection('posts')
            .where('uid', whereIn: moreUserIds.take(10).toList())
            .orderBy('timestamp', descending: true)
            .limit(_postLimit)
            .get();

        if (postQuery.docs.isEmpty) {
          _hasMore = false;
        } else {
          _lastDocument = postQuery.docs.last;
          _posts.addAll(postQuery.docs);
        }
      }
    } catch (e) {
      debugPrint('Error loading more username posts: $e');
    }
  }

  Future<void> refreshSearchResults(String query, SearchType type) async {
    _posts = [];
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();
    await searchPosts(query, type);
  }
}