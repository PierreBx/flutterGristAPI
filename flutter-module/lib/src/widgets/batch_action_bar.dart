import 'package:flutter/material.dart';
import '../utils/batch_operations_utils.dart';

/// A batch action bar widget for table selection and bulk operations.
///
/// Features:
/// - Selection count display
/// - Select all/deselect all buttons
/// - Custom batch action buttons
/// - Confirmation dialogs
/// - Progress indication
/// - Customizable styling
class BatchActionBar extends StatelessWidget {
  /// Batch operations manager
  final BatchOperationsManager manager;

  /// List of batch actions
  final List<BatchAction> actions;

  /// Background color
  final Color? backgroundColor;

  /// Text color
  final Color? textColor;

  /// Whether to show select all/deselect all button
  final bool showSelectAll;

  /// Whether to show close button
  final bool showClose;

  /// Callback when close is pressed
  final VoidCallback? onClose;

  /// Elevation
  final double elevation;

  const BatchActionBar({
    Key? key,
    required this.manager,
    this.actions = const [],
    this.backgroundColor,
    this.textColor,
    this.showSelectAll = true,
    this.showClose = true,
    this.onClose,
    this.elevation = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        if (!manager.hasSelection) {
          return SizedBox.shrink();
        }

        final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primaryContainer;
        final txtColor = textColor ?? Theme.of(context).colorScheme.onPrimaryContainer;

        return Material(
          elevation: elevation,
          color: bgColor,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Selection count
                Icon(Icons.check_circle, color: txtColor, size: 20),
                SizedBox(width: 8),
                Text(
                  '${manager.selectedCount} selected',
                  style: TextStyle(
                    color: txtColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                SizedBox(width: 16),

                // Select all / Deselect all
                if (showSelectAll)
                  TextButton.icon(
                    onPressed: () {
                      if (manager.allSelected) {
                        manager.deselectAll();
                      } else {
                        manager.selectAll();
                      }
                    },
                    icon: Icon(
                      manager.allSelected ? Icons.deselect : Icons.select_all,
                      size: 18,
                    ),
                    label: Text(manager.allSelected ? 'Deselect All' : 'Select All'),
                    style: TextButton.styleFrom(
                      foregroundColor: txtColor,
                    ),
                  ),

                Spacer(),

                // Action buttons
                ...actions.where((action) => action.enabled).map((action) {
                  return Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: _BatchActionButton(
                      action: action,
                      manager: manager,
                      textColor: txtColor,
                    ),
                  );
                }),

                // Close button
                if (showClose) ...[
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      manager.deselectAll();
                      onClose?.call();
                    },
                    icon: Icon(Icons.close, color: txtColor),
                    tooltip: 'Close',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Individual batch action button
class _BatchActionButton extends StatefulWidget {
  final BatchAction action;
  final BatchOperationsManager manager;
  final Color textColor;

  const _BatchActionButton({
    required this.action,
    required this.manager,
    required this.textColor,
  });

  @override
  State<_BatchActionButton> createState() => _BatchActionButtonState();
}

class _BatchActionButtonState extends State<_BatchActionButton> {
  bool _isExecuting = false;

  Future<void> _executeAction() async {
    // Show confirmation if required
    if (widget.action.requiresConfirmation) {
      final confirmed = await _showConfirmation();
      if (!confirmed) return;
    }

    setState(() => _isExecuting = true);

    try {
      await widget.action.onExecute(widget.manager.selectedIds);

      if (mounted) {
        // Clear selection after successful action
        widget.manager.deselectAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExecuting = false);
      }
    }
  }

  Future<bool> _showConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Confirm ${widget.action.label}'),
          ],
        ),
        content: Text(
          widget.action.confirmationMessage ??
              'Are you sure you want to ${widget.action.label.toLowerCase()} ${widget.manager.selectedCount} item(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.action.color,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isExecuting) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(widget.textColor),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _executeAction,
      icon: Icon(widget.action.icon, size: 18),
      label: Text(widget.action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.action.color,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Compact batch action bar (icon buttons only)
class CompactBatchActionBar extends StatelessWidget {
  final BatchOperationsManager manager;
  final List<BatchAction> actions;
  final VoidCallback? onClose;

  const CompactBatchActionBar({
    Key? key,
    required this.manager,
    this.actions = const [],
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        if (!manager.hasSelection) {
          return SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${manager.selectedCount}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              ...actions.where((action) => action.enabled).map((action) {
                return IconButton(
                  onPressed: () async {
                    await action.onExecute(manager.selectedIds);
                    manager.deselectAll();
                  },
                  icon: Icon(action.icon, size: 20),
                  color: action.color,
                  tooltip: action.label,
                );
              }),
              IconButton(
                onPressed: () {
                  manager.deselectAll();
                  onClose?.call();
                },
                icon: Icon(Icons.close, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Floating batch action bar (appears at bottom)
class FloatingBatchActionBar extends StatelessWidget {
  final BatchOperationsManager manager;
  final List<BatchAction> actions;
  final VoidCallback? onClose;

  const FloatingBatchActionBar({
    Key? key,
    required this.manager,
    this.actions = const [],
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        if (!manager.hasSelection) {
          return SizedBox.shrink();
        }

        return Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 12),
                  Text(
                    '${manager.selectedCount} selected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Spacer(),
                  ...actions.where((action) => action.enabled).map((action) {
                    return Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await action.onExecute(manager.selectedIds);
                          manager.deselectAll();
                        },
                        icon: Icon(action.icon, size: 18),
                        label: Text(action.label),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: action.color,
                        ),
                      ),
                    );
                  }),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      manager.deselectAll();
                      onClose?.call();
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Checkbox for table row selection
class BatchSelectionCheckbox extends StatelessWidget {
  final String id;
  final BatchOperationsManager manager;

  const BatchSelectionCheckbox({
    Key? key,
    required this.id,
    required this.manager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        return Checkbox(
          value: manager.isSelected(id),
          onChanged: (value) {
            manager.toggleSelection(id);
          },
        );
      },
    );
  }
}

/// Select all checkbox for table header
class BatchSelectAllCheckbox extends StatelessWidget {
  final BatchOperationsManager manager;

  const BatchSelectAllCheckbox({
    Key? key,
    required this.manager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        return Checkbox(
          value: manager.allSelected,
          tristate: true,
          onChanged: (value) {
            if (manager.allSelected) {
              manager.deselectAll();
            } else {
              manager.selectAll();
            }
          },
        );
      },
    );
  }
}
