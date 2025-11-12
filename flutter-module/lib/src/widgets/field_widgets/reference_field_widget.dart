import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/grist_service.dart';

/// A widget for selecting a reference to another record (foreign key).
///
/// Features:
/// - Autocomplete dropdown with search
/// - Fetches records from referenced table
/// - Displays formatted labels from multiple fields
/// - Returns the selected record's ID
///
/// Example:
/// ```dart
/// ReferenceFieldWidget(
///   label: 'Manager',
///   referenceTable: 'Users',
///   displayFields: ['name', 'email'],
///   valueField: 'id',
///   value: currentManagerId,
///   onChanged: (recordId) => setState(() => managerId = recordId),
/// )
/// ```
class ReferenceFieldWidget extends StatefulWidget {
  /// Label for the field
  final String label;

  /// The table to fetch reference records from
  final String referenceTable;

  /// Fields to display in the dropdown (e.g., ['name', 'email'])
  final List<String> displayFields;

  /// Field to use as the value (typically 'id')
  final String valueField;

  /// Current selected value (record ID)
  final dynamic value;

  /// Callback when selection changes
  final ValueChanged<dynamic>? onChanged;

  /// Whether the field is required
  final bool required;

  /// Custom validator
  final String? Function(String?)? validator;

  /// Whether the field is enabled
  final bool enabled;

  /// Optional hint text
  final String? hint;

  /// Separator for display fields (default: ' - ')
  final String displaySeparator;

  /// Whether to show a clear button
  final bool showClearButton;

  const ReferenceFieldWidget({
    super.key,
    required this.label,
    required this.referenceTable,
    required this.displayFields,
    this.valueField = 'id',
    this.value,
    this.onChanged,
    this.required = false,
    this.validator,
    this.enabled = true,
    this.hint,
    this.displaySeparator = ' - ',
    this.showClearButton = true,
  });

  @override
  State<ReferenceFieldWidget> createState() => _ReferenceFieldWidgetState();
}

class _ReferenceFieldWidgetState extends State<ReferenceFieldWidget> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _selectedRecord;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void didUpdateWidget(ReferenceFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.referenceTable != widget.referenceTable) {
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gristService = Provider.of<GristService>(context, listen: false);
      final records = await gristService.fetchRecords(widget.referenceTable);

      setState(() {
        _records = records;
        _isLoading = false;

        // Find selected record if value is set
        if (widget.value != null) {
          _selectedRecord = _records.firstWhere(
            (r) => _getFieldValue(r, widget.valueField) == widget.value,
            orElse: () => {},
          );
          if (_selectedRecord!.isEmpty) {
            _selectedRecord = null;
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  dynamic _getFieldValue(Map<String, dynamic> record, String fieldName) {
    final fields = record['fields'] as Map<String, dynamic>?;
    return fields?[fieldName];
  }

  String _formatDisplayText(Map<String, dynamic> record) {
    final parts = <String>[];
    for (final field in widget.displayFields) {
      final value = _getFieldValue(record, field);
      if (value != null && value.toString().isNotEmpty) {
        parts.add(value.toString());
      }
    }
    return parts.join(widget.displaySeparator);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
            const SizedBox(height: 4),
            const Text(
              'Loading options...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error loading options: $_error',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _loadRecords,
                    tooltip: 'Retry',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Autocomplete<Map<String, dynamic>>(
        initialValue: _selectedRecord != null
            ? TextEditingValue(text: _formatDisplayText(_selectedRecord!))
            : null,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return _records;
          }
          return _records.where((record) {
            final displayText = _formatDisplayText(record).toLowerCase();
            return displayText.contains(textEditingValue.text.toLowerCase());
          });
        },
        displayStringForOption: _formatDisplayText,
        onSelected: (Map<String, dynamic> selection) {
          final value = _getFieldValue(selection, widget.valueField);
          setState(() {
            _selectedRecord = selection;
          });
          widget.onChanged?.call(value);
        },
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint ?? 'Search...',
              border: const OutlineInputBorder(),
              suffixIcon: widget.showClearButton && _selectedRecord != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: widget.enabled
                          ? () {
                              textEditingController.clear();
                              setState(() {
                                _selectedRecord = null;
                              });
                              widget.onChanged?.call(null);
                            }
                          : null,
                    )
                  : const Icon(Icons.arrow_drop_down),
            ),
            validator: widget.validator ??
                (widget.required
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return '${widget.label} is required';
                        }
                        return null;
                      }
                    : null),
            enabled: widget.enabled,
          );
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<Map<String, dynamic>> onSelected,
          Iterable<Map<String, dynamic>> options,
        ) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: ListTile(
                        title: Text(_formatDisplayText(option)),
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
