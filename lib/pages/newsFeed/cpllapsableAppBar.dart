import 'package:flutter/material.dart';
import 'dart:ui';

class CollapsibleAppBar extends StatefulWidget {
  final Animation<Offset> offsetAnimation;
  final VoidCallback onFilterPressed;
  final Function(String, SearchType) onSearch;

  const CollapsibleAppBar({
    Key? key,
    required this.offsetAnimation,
    required this.onFilterPressed,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<CollapsibleAppBar> createState() => _CollapsibleAppBarState();
}

enum SearchType { title, topic, username }

class _CollapsibleAppBarState extends State<CollapsibleAppBar>
    with TickerProviderStateMixin {
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  SearchType _searchType = SearchType.title;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchScaleAnimation;
  late Animation<double> _searchOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutBack,
    ));
    _searchOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
      }
    });
  }

  void _performSearch() {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isNotEmpty) {
      widget.onSearch(searchTerm, _searchType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: widget.offsetAnimation,
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.5),
                    ]
                        : [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: false,
                  leading: _isSearchMode
                      ? AnimatedBuilder(
                    animation: _searchOpacityAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _searchOpacityAnimation.value,
                        child: Transform.scale(
                          scale: _searchScaleAnimation.value,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1),
                                width: 0.5,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded),
                              color: Colors.orange[700],
                              iconSize: 20,
                              onPressed: _toggleSearchMode,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                      : null,
                  title: _isSearchMode
                      ? AnimatedBuilder(
                    animation: _searchOpacityAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _searchOpacityAnimation.value,
                        child: Transform.scale(
                          scale: _searchScaleAnimation.value,
                          child: _buildSearchField(theme, isDark),
                        ),
                      );
                    },
                  )
                      : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange[600]!.withOpacity(0.8),
                              Colors.orange[800]!.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.orange[700]!,
                            Colors.orange[900]!,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'NoteHub Feed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: _isSearchMode
                      ? [
                    AnimatedBuilder(
                      animation: _searchOpacityAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _searchOpacityAnimation.value,
                          child: Transform.scale(
                            scale: _searchScaleAnimation.value,
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: DropdownButton<SearchType>(
                                value: _searchType,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.orange[700],
                                  size: 20,
                                ),
                                underline: Container(),
                                dropdownColor: isDark
                                    ? Colors.grey[900]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                onChanged: (SearchType? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _searchType = newValue;
                                    });
                                  }
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: SearchType.title,
                                    child: Text(
                                      'Title',
                                      style: TextStyle(
                                        color: theme.textTheme.bodyMedium?.color,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: SearchType.topic,
                                    child: Text(
                                      'Topic',
                                      style: TextStyle(
                                        color: theme.textTheme.bodyMedium?.color,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: SearchType.username,
                                    child: Text(
                                      'Username',
                                      style: TextStyle(
                                        color: theme.textTheme.bodyMedium?.color,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ]
                      : [
                    _buildGlassButton(
                      icon: Icons.search_rounded,
                      onPressed: _toggleSearchMode,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: Icons.tune_rounded,
                      onPressed: widget.onFilterPressed,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.orange[700],
        iconSize: 20,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        child: TextField(
          controller: _searchController,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: 'Search by ${_searchType.toString().split('.').last}...',
            hintStyle: TextStyle(
              color: theme.hintColor?.withOpacity(0.7),
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            suffixIcon: Container(
              margin: const EdgeInsets.only(left: 8, right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[600]!.withOpacity(0.8),
                    Colors.orange[800]!.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.search_rounded),
                color: Colors.white,
                iconSize: 16,
                onPressed: _performSearch,
              ),
            ),
          ),
          onSubmitted: (_) => _performSearch(),
          textInputAction: TextInputAction.search,
          autofocus: true,
        ),
      ),

    );
  }
}