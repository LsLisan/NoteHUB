import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class PostANotePage extends StatefulWidget {
  const PostANotePage({super.key});

  @override
  State<PostANotePage> createState() => _PostPageState();
}

class _PostPageState extends State<PostANotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  bool _isLoading = false;
  int _wordCount = 0;
  int _charCount = 0;
  String _selectedFontSize = '14';

  final List<String> _fontSizes = ['10', '12', '14', '16', '18', '20', '24', '28'];

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final text = _descriptionController.text;
    setState(() {
      _charCount = text.length;
      _wordCount = text.isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
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

    // Find the start of the current line
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

  void _submitPost() async {
    if (_titleController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _showSnackBar('All fields are required.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('posts').add({
          'uid': user.uid,
          'title': _titleController.text.trim(),
          'subject': _subjectController.text.trim(),
          'description': _descriptionController.text.trim(),
          'wordCount': _wordCount,
          'charCount': _charCount,
          'timestamp': FieldValue.serverTimestamp(),
          'lastModified': FieldValue.serverTimestamp(),
        });

        _showSnackBar('Note published successfully!', isError: false);
        _clearForm();
      } else {
        _showSnackBar('User not authenticated. Please log in.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to publish note: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveDraft() async {
    if (_titleController.text.trim().isEmpty && _descriptionController.text.trim().isEmpty) {
      _showSnackBar('Nothing to save as draft.', isError: true);
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('drafts').add({
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

  void _clearForm() {
    _titleController.clear();
    _subjectController.clear();
    _descriptionController.clear();
    setState(() {
      _isBold = false;
      _isItalic = false;
      _isUnderlined = false;
      _wordCount = 0;
      _charCount = 0;
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Text Editor'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Draft'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
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
                          "New Post",
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
                        labelText: 'Post Title',
                        hintText: 'Enter a compelling title...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                          hintText: 'Start writing your document here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.all(16),
                          alignLabelWithHint: true,
                        ),
                        onChanged: (value) => _updateWordCount(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Word Count and Actions
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildWordCountDisplay(),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _clearForm,
                              icon: const Icon(Icons.clear_all, size: 8),
                              label: const Text('Clear All'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _submitPost,
                              icon: _isLoading
                                  ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.publish, size: 16),
                              label: Text(_isLoading ? 'Posting...' : 'Post'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 50,)
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}