import 'package:flutter/material.dart';

/// Utility class for managing batch operations on records.
///
/// Features:
/// - Select/deselect records
/// - Select all/deselect all
/// - Batch delete
/// - Batch export
/// - Batch update
/// - Custom batch actions
class BatchOperationsManager extends ChangeNotifier {
  /// Set of selected record IDs
  final Set<String> _selectedIds = {};

  /// All available record IDs
  List<String> _allIds = [];

  /// Get selected IDs
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  /// Get count of selected items
  int get selectedCount => _selectedIds.length;

  /// Check if any items are selected
  bool get hasSelection => _selectedIds.isNotEmpty;

  /// Check if all items are selected
  bool get allSelected => _allIds.isNotEmpty && _selectedIds.length == _allIds.length;

  /// Check if specific ID is selected
  bool isSelected(String id) => _selectedIds.contains(id);

  /// Set all available IDs
  void setAllIds(List<String> ids) {
    _allIds = ids;
    // Remove any selected IDs that are no longer in the list
    _selectedIds.retainWhere((id) => _allIds.contains(id));
    notifyListeners();
  }

  /// Toggle selection of a single item
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  /// Select a single item
  void select(String id) {
    if (!_selectedIds.contains(id)) {
      _selectedIds.add(id);
      notifyListeners();
    }
  }

  /// Deselect a single item
  void deselect(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      notifyListeners();
    }
  }

  /// Select all items
  void selectAll() {
    _selectedIds.clear();
    _selectedIds.addAll(_allIds);
    notifyListeners();
  }

  /// Deselect all items
  void deselectAll() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// Clear selection (alias for deselectAll)
  void clear() {
    deselectAll();
  }

  /// Select multiple items
  void selectMultiple(List<String> ids) {
    for (var id in ids) {
      if (_allIds.contains(id)) {
        _selectedIds.add(id);
      }
    }
    notifyListeners();
  }

  /// Deselect multiple items
  void deselectMultiple(List<String> ids) {
    _selectedIds.removeWhere((id) => ids.contains(id));
    notifyListeners();
  }

  /// Invert selection
  void invertSelection() {
    final newSelection = _allIds.where((id) => !_selectedIds.contains(id)).toSet();
    _selectedIds.clear();
    _selectedIds.addAll(newSelection);
    notifyListeners();
  }

  /// Get selected records from list of records
  List<T> getSelectedRecords<T>(List<T> records, String Function(T) idGetter) {
    return records.where((record) => _selectedIds.contains(idGetter(record))).toList();
  }

  @override
  void dispose() {
    _selectedIds.clear();
    _allIds.clear();
    super.dispose();
  }
}

/// Batch action definition
class BatchAction {
  /// Action identifier
  final String id;

  /// Action label
  final String label;

  /// Action icon
  final IconData icon;

  /// Action color
  final Color? color;

  /// Whether this action requires confirmation
  final bool requiresConfirmation;

  /// Confirmation message
  final String? confirmationMessage;

  /// Callback when action is triggered
  final Future<void> Function(Set<String> selectedIds) onExecute;

  /// Whether this action is enabled
  final bool enabled;

  const BatchAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onExecute,
    this.color,
    this.requiresConfirmation = false,
    this.confirmationMessage,
    this.enabled = true,
  });
}

/// Predefined batch actions
class BatchActions {
  /// Delete action
  static BatchAction delete({
    required Future<void> Function(Set<String>) onDelete,
  }) {
    return BatchAction(
      id: 'delete',
      label: 'Delete',
      icon: Icons.delete,
      color: Colors.red,
      requiresConfirmation: true,
      confirmationMessage: 'Are you sure you want to delete the selected items?',
      onExecute: onDelete,
    );
  }

  /// Export action
  static BatchAction export({
    required Future<void> Function(Set<String>) onExport,
  }) {
    return BatchAction(
      id: 'export',
      label: 'Export',
      icon: Icons.download,
      onExecute: onExport,
    );
  }

  /// Duplicate action
  static BatchAction duplicate({
    required Future<void> Function(Set<String>) onDuplicate,
  }) {
    return BatchAction(
      id: 'duplicate',
      label: 'Duplicate',
      icon: Icons.content_copy,
      onExecute: onDuplicate,
    );
  }

  /// Archive action
  static BatchAction archive({
    required Future<void> Function(Set<String>) onArchive,
  }) {
    return BatchAction(
      id: 'archive',
      label: 'Archive',
      icon: Icons.archive,
      onExecute: onArchive,
    );
  }

  /// Move to action
  static BatchAction moveTo({
    required Future<void> Function(Set<String>) onMove,
  }) {
    return BatchAction(
      id: 'move',
      label: 'Move To',
      icon: Icons.drive_file_move,
      onExecute: onMove,
    );
  }

  /// Tag action
  static BatchAction tag({
    required Future<void> Function(Set<String>) onTag,
  }) {
    return BatchAction(
      id: 'tag',
      label: 'Add Tag',
      icon: Icons.label,
      onExecute: onTag,
    );
  }

  /// Print action
  static BatchAction print({
    required Future<void> Function(Set<String>) onPrint,
  }) {
    return BatchAction(
      id: 'print',
      label: 'Print',
      icon: Icons.print,
      onExecute: onPrint,
    );
  }

  /// Share action
  static BatchAction share({
    required Future<void> Function(Set<String>) onShare,
  }) {
    return BatchAction(
      id: 'share',
      label: 'Share',
      icon: Icons.share,
      onExecute: onShare,
    );
  }
}

/// Batch operation result
class BatchOperationResult {
  /// Number of successful operations
  final int successCount;

  /// Number of failed operations
  final int failureCount;

  /// Error messages for failed operations
  final List<String> errors;

  /// Whether the operation was cancelled
  final bool cancelled;

  const BatchOperationResult({
    required this.successCount,
    required this.failureCount,
    this.errors = const [],
    this.cancelled = false,
  });

  /// Check if all operations succeeded
  bool get allSucceeded => failureCount == 0 && !cancelled;

  /// Check if any operations failed
  bool get hasFailures => failureCount > 0;

  /// Get total operations attempted
  int get totalCount => successCount + failureCount;
}

/// Execute a batch operation with progress tracking
Future<BatchOperationResult> executeBatchOperation({
  required BuildContext context,
  required Set<String> selectedIds,
  required Future<bool> Function(String id) operation,
  String? progressMessage,
  bool showProgress = true,
}) async {
  int successCount = 0;
  int failureCount = 0;
  List<String> errors = [];

  // Show progress dialog if requested
  if (showProgress && context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(progressMessage ?? 'Processing...'),
          ],
        ),
      ),
    );
  }

  // Execute operation for each selected ID
  for (var id in selectedIds) {
    try {
      final success = await operation(id);
      if (success) {
        successCount++;
      } else {
        failureCount++;
        errors.add('Failed to process item: $id');
      }
    } catch (e) {
      failureCount++;
      errors.add('Error processing item $id: $e');
    }
  }

  // Close progress dialog
  if (showProgress && context.mounted) {
    Navigator.of(context).pop();
  }

  return BatchOperationResult(
    successCount: successCount,
    failureCount: failureCount,
    errors: errors,
  );
}

/// Show result dialog after batch operation
void showBatchOperationResult({
  required BuildContext context,
  required BatchOperationResult result,
  String? successMessage,
  String? failureMessage,
}) {
  if (result.cancelled) {
    return;
  }

  final message = result.allSucceeded
      ? (successMessage ?? 'Successfully processed ${result.successCount} item(s)')
      : (failureMessage ?? 'Processed ${result.successCount} item(s), ${result.failureCount} failed');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            result.allSucceeded ? Icons.check_circle : Icons.warning,
            color: result.allSucceeded ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 12),
          Text(result.allSucceeded ? 'Success' : 'Partial Success'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (result.hasFailures && result.errors.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Errors:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.errors.map((error) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $error',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
