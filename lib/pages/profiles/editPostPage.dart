import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class EditPostPage extends StatefulWidget {
  final String postID;

  const EditPostPage({Key? key, required this.postID}) : super(key: key);

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAuthorized = false;
  bool _hasChanges = false;
  String _postOwnerId = '';

  // Formatting states
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  int _wordCount = 0;
  int _charCount = 0;
  String _selectedFontSize = '14';

  // Original data for comparison
  String _originalTitle = '';
  String _originalSubject = '';
  String _originalDescription = '';

  final List<String> _fontSizes = ['10', '12', '14', '16', '18', '20', '24', '28'];

  @override
  void initState() {
    super.initState();
    _loadPostData();
    _setupChangeListeners();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _setupChangeListeners() {
    _titleController.addListener(_checkForChanges);
    _subjectController.addListener(_checkForChanges);
    _descriptionController.addListener(() {
      _updateWordCount();
      _checkForChanges();
    });
  }

  void _checkForChanges() {
    final hasChanges = _titleController.text != _originalTitle ||
        _subjectController.text != _originalSubject ||
        _descriptionController.text != _originalDescription;

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  void _updateWordCount() {
    final text = _descriptionController.text;
    setState(() {
      _charCount = text.length;
      _wordCount = text.isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _loadPostData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        _showSnackBar('Please sign in to edit posts', isError: true);
        Navigator.pop(context);
        return;
      }

      DocumentSnapshot postDoc = await _firestore.collection('posts').doc(widget.postID).get();

      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        _postOwnerId = postData['uid'] ?? '';

        _isAuthorized = _postOwnerId == currentUser.uid;

        if (!_isAuthorized) {
          _showSnackBar('You do not have permission to edit this post', isError: true);
          Navigator.pop(context);
          return;
        }

        // Store original data
        _originalTitle = postData['title'] ?? '';
        _originalSubject = postData['subject'] ?? '';
        _originalDescription = postData['description'] ?? '';

        setState(() {
          _titleController.text = _originalTitle;
          _descriptionController.text = _originalDescription;
          _subjectController.text = _originalSubject;
          _isLoading = false;
        });

        _updateWordCount();
      } else {
        _showSnackBar('Post not found', isError: true);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error loading post data: $e');
      _showSnackBar('Failed to load post data', isError: true);
      Navigator.pop(context);
    }
  }

  void _insertFormattedText(String prefix, String suffix) {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;

    if (selection.isValid) {
      final selectedText = selection.textInside(text);
      final newText = '$prefix$selectedText$suffix';

      _descriptionController.value = _descriptionController.value.copyWith(
        text: text.replaceRange(selection.start, selection.end, newText),
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
      );
    }
  }

  void _toggleBold() {
    setState(() => _isBold = !_isBold);
    if (_descriptionController.selection.isValid) {
      _insertFormattedText('**', '**');
    }
    HapticFeedback.lightImpact();
  }

  void _toggleItalic() {
    setState(() => _isItalic = !_isItalic);
    if (_descriptionController.selection.isValid) {
      _insertFormattedText('*', '*');
    }
    HapticFeedback.lightImpact();
  }

  void _toggleUnderline() {
    setState(() => _isUnderlined = !_isUnderlined);
    if (_descriptionController.selection.isValid) {
      _insertFormattedText('<u>', '</u>');
    }
    HapticFeedback.lightImpact();
  }

  void _insertBulletPoint() {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;
    final cursorPos = selection.baseOffset;

    int lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;

    final bulletText = '• ';
    final newText = text.substring(0, lineStart) + bulletText + text.substring(lineStart);

    _descriptionController.value = _descriptionController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart + bulletText.length),
    );
    HapticFeedback.lightImpact();
  }

  void _insertNumberedList() {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;
    final cursorPos = selection.baseOffset;

    int lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;

    final numberedText = '1. ';
    final newText = text.substring(0, lineStart) + numberedText + text.substring(lineStart);

    _descriptionController.value = _descriptionController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart + numberedText.length),
    );
    HapticFeedback.lightImpact();
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    final User? currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != _postOwnerId) {
      _showSnackBar('You do not have permission to edit this post', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('posts').doc(widget.postID).update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'subject': _subjectController.text.trim(),
        'wordCount': _wordCount,
        'charCount': _charCount,
        'lastModified': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Post updated successfully!', isError: false);

      // Update original data to reflect changes
      _originalTitle = _titleController.text.trim();
      _originalSubject = _subjectController.text.trim();
      _originalDescription = _descriptionController.text.trim();

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error updating post: $e');
      _showSnackBar('Failed to update post: ${e.toString()}', isError: true);
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!_hasChanges) {
      _showSnackBar('No changes to save', isError: true);
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('post_drafts').doc(widget.postID).set({
          'originalPostId': widget.postID,
          'uid': user.uid,
          'title': _titleController.text.trim(),
          'subject': _subjectController.text.trim(),
          'description': _descriptionController.text.trim(),
          'wordCount': _wordCount,
          'charCount': _charCount,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _showSnackBar('Draft saved successfully!', isError: false);
      }
    } catch (e) {
      _showSnackBar('Failed to save draft: ${e.toString()}', isError: true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false);
              _savePost();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _buildToolbarButton(
            icon: Icons.format_bold,
            isActive: _isBold,
            onPressed: _toggleBold,
            tooltip: 'Bold (Ctrl+B)',
          ),
          _buildToolbarButton(
            icon: Icons.format_italic,
            isActive: _isItalic,
            onPressed: _toggleItalic,
            tooltip: 'Italic (Ctrl+I)',
          ),
          _buildToolbarButton(
            icon: Icons.format_underlined,
            isActive: _isUnderlined,
            onPressed: _toggleUnderline,
            tooltip: 'Underline (Ctrl+U)',
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            onPressed: _insertBulletPoint,
            tooltip: 'Bullet List',
          ),
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            onPressed: _insertNumberedList,
            tooltip: 'Numbered List',
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFontSize,
                items: _fontSizes.map((size) => DropdownMenuItem(
                  value: size,
                  child: Text('${size}px'),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedFontSize = value!);
                },
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
            borderRadius: BorderRadius.circular(6),
            border: isActive ? Border.all(color: Theme.of(context).colorScheme.primary) : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );
  }

  Widget _buildWordCountDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$_wordCount words • $_charCount characters',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text('Edit Note'),
              if (_hasChanges) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Modified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          elevation: 0,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          actions: [
            if (!_isLoading && _isAuthorized) ...[
              TextButton.icon(
                onPressed: _hasChanges ? _saveDraft : null,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Draft'),
                style: TextButton.styleFrom(
                  foregroundColor: _hasChanges ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _hasChanges && !_isSaving ? _savePost : null,
                tooltip: 'Save Changes',
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading document...'),
            ],
          ),
        )
            : !_isAuthorized
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You do not have permission to edit this document'),
            ],
          ),
        )
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_document, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              "Edit Document",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Title Field
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Document Title',
                            hintText: 'Enter a compelling title...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Subject Field
                        TextFormField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            labelText: 'Subject/Category',
                            hintText: 'Specify the topic or category...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.category),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a subject';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Formatting Section
                        Row(
                          children: [
                            Icon(Icons.format_paint, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              "Formatting Tools",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildFormattingToolbar(),
                        const SizedBox(height: 16),

                        // Text Editor
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: TextFormField(
                            controller: _descriptionController,
                            focusNode: _descriptionFocusNode,
                            maxLines: 15,
                            style: TextStyle(
                              fontSize: double.parse(_selectedFontSize),
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'Edit your document content here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.all(16),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Word Count and Actions
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildWordCountDisplay(),
                            Column(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final shouldDiscard = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Discard Changes'),
                                        content: const Text('Are you sure you want to discard all changes?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Discard'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldDiscard == true) {
                                      setState(() {
                                        _titleController.text = _originalTitle;
                                        _subjectController.text = _originalSubject;
                                        _descriptionController.text = _originalDescription;
                                        _hasChanges = false;
                                      });
                                      _updateWordCount();
                                    }
                                  },
                                  icon: const Icon(Icons.restore, size: 18),
                                  label: const Text('Discard Changes'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _savePost,
                                  icon: _isSaving
                                      ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : const Icon(Icons.save, size: 18),
                                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}