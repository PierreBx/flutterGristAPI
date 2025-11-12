import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// A rich text editor field widget with WYSIWYG capabilities.
///
/// Features:
/// - Full WYSIWYG text editing
/// - Formatting toolbar (bold, italic, underline, strikethrough)
/// - Text alignment (left, center, right, justify)
/// - Headers (H1, H2, H3)
/// - Lists (bullet, numbered)
/// - Links
/// - Code blocks
/// - Quotes
/// - Text and background colors
/// - Font size
/// - Undo/Redo
/// - Store as JSON or HTML
class RichTextFieldWidget extends StatefulWidget {
  /// Field label
  final String label;

  /// Initial value (JSON or plain text)
  final String? value;

  /// Callback when value changes
  final ValueChanged<String>? onChanged;

  /// Whether the field is read-only
  final bool readOnly;

  /// Minimum height of the editor
  final double minHeight;

  /// Maximum height of the editor
  final double? maxHeight;

  /// Placeholder text
  final String? placeholder;

  /// Whether to show the toolbar
  final bool showToolbar;

  /// Toolbar position (top or bottom)
  final ToolbarPosition toolbarPosition;

  const RichTextFieldWidget({
    Key? key,
    required this.label,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.minHeight = 200,
    this.maxHeight,
    this.placeholder,
    this.showToolbar = true,
    this.toolbarPosition = ToolbarPosition.top,
  }) : super(key: key);

  @override
  State<RichTextFieldWidget> createState() => _RichTextFieldWidgetState();
}

class _RichTextFieldWidgetState extends State<RichTextFieldWidget> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    quill.Document document;

    if (widget.value != null && widget.value!.isNotEmpty) {
      try {
        // Try to parse as JSON (Quill Delta format)
        final json = jsonDecode(widget.value!);
        document = quill.Document.fromJson(json);
      } catch (e) {
        // If not JSON, treat as plain text
        document = quill.Document()..insert(0, widget.value!);
      }
    } else {
      document = quill.Document();
    }

    _controller = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Listen to changes
    if (widget.onChanged != null) {
      _controller.addListener(_handleChange);
    }
  }

  void _handleChange() {
    if (widget.onChanged != null && !widget.readOnly) {
      // Convert document to JSON
      final json = jsonEncode(_controller.document.toDelta().toJson());
      widget.onChanged!(json);
    }
  }

  @override
  void didUpdateWidget(RichTextFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller if value changed externally
    if (widget.value != oldWidget.value) {
      _controller.removeListener(_handleChange);
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: 8),
        ],

        // Toolbar (top)
        if (widget.showToolbar && widget.toolbarPosition == ToolbarPosition.top)
          _buildToolbar(),

        // Editor
        Container(
          constraints: BoxConstraints(
            minHeight: widget.minHeight,
            maxHeight: widget.maxHeight ?? double.infinity,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: quill.QuillEditor(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: ScrollController(),
            scrollable: true,
            autoFocus: false,
            readOnly: widget.readOnly,
            expands: false,
            padding: EdgeInsets.all(16),
            placeholder: widget.placeholder ?? 'Enter text...',
          ),
        ),

        // Toolbar (bottom)
        if (widget.showToolbar && widget.toolbarPosition == ToolbarPosition.bottom) ...[
          SizedBox(height: 8),
          _buildToolbar(),
        ],
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: quill.QuillToolbar.simple(
        configurations: quill.QuillSimpleToolbarConfigurations(
          controller: _controller,
          sharedConfigurations: const quill.QuillSharedConfigurations(),
          multiRowsDisplay: false,
          showAlignmentButtons: true,
          showBackgroundColorButton: true,
          showBoldButton: true,
          showCenterAlignment: true,
          showClearFormat: true,
          showCodeBlock: true,
          showColorButton: true,
          showDirection: false,
          showDividers: true,
          showFontFamily: false,
          showFontSize: true,
          showHeaderStyle: true,
          showIndent: true,
          showInlineCode: true,
          showItalicButton: true,
          showJustifyAlignment: true,
          showLeftAlignment: true,
          showLink: true,
          showListBullets: true,
          showListCheck: true,
          showListNumbers: true,
          showQuote: true,
          showRedo: true,
          showRightAlignment: true,
          showSearchButton: false,
          showSmallButton: false,
          showStrikeThrough: true,
          showSubscript: false,
          showSuperscript: false,
          showUnderLineButton: true,
          showUndo: true,
        ),
      ),
    );
  }

  /// Get plain text from the document
  String getPlainText() {
    return _controller.document.toPlainText();
  }

  /// Get HTML representation (simplified)
  String toHtml() {
    // This is a simplified HTML conversion
    // For production, you might want to use a dedicated package
    final text = _controller.document.toPlainText();
    return '<p>$text</p>';
  }
}

/// Position of the toolbar
enum ToolbarPosition {
  top,
  bottom,
}

/// Compact rich text editor without toolbar
class CompactRichTextFieldWidget extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final String? placeholder;

  const CompactRichTextFieldWidget({
    Key? key,
    required this.label,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichTextFieldWidget(
      label: label,
      value: value,
      onChanged: onChanged,
      readOnly: readOnly,
      placeholder: placeholder,
      showToolbar: false,
      minHeight: 100,
      maxHeight: 200,
    );
  }
}

/// Read-only rich text viewer
class RichTextViewer extends StatelessWidget {
  /// Content to display (JSON or plain text)
  final String content;

  /// Minimum height
  final double minHeight;

  /// Maximum height
  final double? maxHeight;

  const RichTextViewer({
    Key? key,
    required this.content,
    this.minHeight = 100,
    this.maxHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    quill.Document document;

    try {
      // Try to parse as JSON
      final json = jsonDecode(content);
      document = quill.Document.fromJson(json);
    } catch (e) {
      // If not JSON, treat as plain text
      document = quill.Document()..insert(0, content);
    }

    final controller = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    return Container(
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight ?? double.infinity,
      ),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: quill.QuillEditor(
        controller: controller,
        focusNode: FocusNode(),
        scrollController: ScrollController(),
        scrollable: true,
        autoFocus: false,
        readOnly: true,
        expands: false,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
