import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notehub/pages/newsFeed/cpllapsableAppBar.dart';
import 'package:notehub/pages/newsFeed/postCard.dart';
import 'package:notehub/pages/newsFeed/postController.dart';


class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  final PostController _postController = PostController();
  bool _showAppBar = true;
  bool _isSearchActive = false;
  String _searchQuery = '';
  SearchType _searchType = SearchType.title;

  @override
  void initState() {
    super.initState();
    _postController.loadInitialPosts();

    // Initialize animation controller for app bar
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Add scroll listener for app bar behavior
    _scrollController.addListener(() {
      _scrollListener();
      _handleAppBarVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleAppBarVisibility() {
    if (_scrollController.hasClients) {
      final bool isScrollingDown = _scrollController.position.userScrollDirection == ScrollDirection.reverse;
      final bool isScrollingUp = _scrollController.position.userScrollDirection == ScrollDirection.forward;

      if (isScrollingDown && _showAppBar) {
        setState(() {
          _showAppBar = false;
          _animationController.forward();
        });
      } else if (isScrollingUp && !_showAppBar) {
        setState(() {
          _showAppBar = true;
          _animationController.reverse();
        });
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_isSearchActive) {
        _postController.loadMoreSearchResults(_searchQuery, _searchType);
      } else {
        _postController.loadMorePosts();
      }
    }
  }

  Future<void> _refresh() async {
    if (_isSearchActive) {
      await _postController.refreshSearchResults(_searchQuery, _searchType);
    } else {
      await _postController.refreshPosts();
    }
    setState(() {});
  }

  void _handleSearch(String query, SearchType type) {
    setState(() {
      _isSearchActive = true;
      _searchQuery = query;
      _searchType = type;
    });
    _postController.searchPosts(query, type);
  }

  void _clearSearch() {
    setState(() {
      _isSearchActive = false;
      _searchQuery = '';
    });
    _postController.refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Add space at top for the app bar
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),

              // Search indicator if search is active
              if (_isSearchActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      Icon(
                        _searchType == SearchType.title
                            ? Icons.title
                            : _searchType == SearchType.topic
                            ? Icons.topic
                            : Icons.person,
                        size: 16,
                        color: Colors.orange[800],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Searching for "$_searchQuery" in ${_searchType.toString().split('.').last}s',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.orange[800],
                        onPressed: _clearSearch,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Posts list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: Colors.orange,
                  child: AnimatedBuilder(
                    animation: _postController,
                    builder: (context, _) {
                      if (_postController.isLoading && _postController.posts.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.orange),
                        );
                      }

                      if (_postController.posts.isEmpty) {
                        return _isSearchActive
                            ? _buildEmptySearchResults(theme)
                            : _buildEmptyState(theme);
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: _postController.posts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _postController.posts.length) {
                            return _postController.isLoading
                                ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(color: Colors.orange),
                                ))
                                : const SizedBox.shrink();
                          }

                          var post = _postController.posts[index];
                          return PostCard(post: post);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Collapsible app bar
          CollapsibleAppBar(
            offsetAnimation: _offsetAnimation,
            onFilterPressed: () {
              // Implement filter functionality
            },
            onSearch: _handleSearch,
          ),
        ],
      ),
      
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            'No posts available',
            style: TextStyle(fontSize: 18, color: theme.disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            'No results found for "$_searchQuery"',
            style: TextStyle(fontSize: 18, color: theme.disabledColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: theme.disabledColor),
          ),
        ],
      ),
    );
  }
}