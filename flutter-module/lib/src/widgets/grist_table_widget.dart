import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'skeleton_loader.dart';
import '../utils/column_filter_utils.dart';

/// Configuration for a table column.
class TableColumnConfig {
  final String name;
  final String label;
  final bool visible;
  final int? width;
  final String? type;
  final bool sortable;

  const TableColumnConfig({
    required this.name,
    required this.label,
    this.visible = true,
    this.width,
    this.type,
    this.sortable = true,
  });

  factory TableColumnConfig.fromMap(Map<String, dynamic> map) {
    return TableColumnConfig(
      name: map['name'] as String,
      label: map['label'] as String? ?? map['name'] as String,
      visible: map['visible'] as bool? ?? true,
      width: map['width'] as int?,
      type: map['type'] as String?,
      sortable: map['sortable'] as bool? ?? true,
    );
  }
}

/// A widget that displays data in a scrollable data table format with sorting and pagination.
class GristTableWidget extends StatefulWidget {
  /// List of column configurations
  final List<TableColumnConfig> columns;

  /// List of data records to display
  final List<Map<String, dynamic>> records;

  /// Callback when a row is tapped
  final void Function(Map<String, dynamic> record)? onRowTap;

  /// Whether the table is in loading state
  final bool isLoading;

  /// Error message to display
  final String? error;

  /// Whether to show the ID column
  final bool showIdColumn;

  /// Rows per page for pagination (null = no pagination)
  final int? rowsPerPage;

  /// Whether to enable sorting
  final bool enableSorting;

  const GristTableWidget({
    super.key,
    required this.columns,
    required this.records,
    this.onRowTap,
    this.isLoading = false,
    this.error,
    this.showIdColumn = false,
    this.rowsPerPage,
    this.enableSorting = true,
  });

  @override
  State<GristTableWidget> createState() => _GristTableWidgetState();
}

class _GristTableWidgetState extends State<GristTableWidget> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<Map<String, dynamic>> _sortedRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  int _currentPage = 0;
  final List<ColumnFilter> _activeFilters = [];

  @override
  void initState() {
    super.initState();
    _sortedRecords = List.from(widget.records);
    _applyFilters();
  }

  @override
  void didUpdateWidget(GristTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.records != oldWidget.records) {
      _sortedRecords = List.from(widget.records);
      if (_sortColumnIndex != null) {
        _sortData(_sortColumnIndex!, _sortAscending);
      }
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      if (_activeFilters.isEmpty) {
        _filteredRecords = List.from(_sortedRecords);
      } else {
        _filteredRecords = _sortedRecords.where((record) {
          return _activeFilters.every((filter) => filter.matches(record));
        }).toList();
      }
      _currentPage = 0; // Reset to first page after filtering
    });
  }

  void _addOrUpdateFilter(ColumnFilter filter) {
    setState(() {
      // Remove existing filter for this column
      _activeFilters.removeWhere((f) => f.columnName == filter.columnName);
      // Add new filter
      _activeFilters.add(filter);
      _applyFilters();
    });
  }

  void _removeFilter(ColumnFilter filter) {
    setState(() {
      _activeFilters.remove(filter);
      _applyFilters();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters.clear();
      _applyFilters();
    });
  }

  Future<void> _showFilterDialog(TableColumnConfig column) async {
    final filter = await showDialog<ColumnFilter>(
      context: context,
      builder: (context) => ColumnFilterDialog(
        columnName: column.name,
        columnLabel: column.label,
        columnType: column.type,
        existingFilter: _activeFilters.firstWhere(
          (f) => f.columnName == column.name,
          orElse: () => ColumnFilter(
            columnName: '',
            columnLabel: '',
            operator: FilterOperator.contains,
          ),
        ).columnName.isEmpty
            ? null
            : _activeFilters.firstWhere((f) => f.columnName == column.name),
      ),
    );

    if (filter != null) {
      _addOrUpdateFilter(filter);
    }
  }

  void _sortData(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      final visibleColumns = widget.columns.where((col) => col.visible).toList();

      // Account for ID column offset
      final actualColumnIndex =
          widget.showIdColumn ? columnIndex - 1 : columnIndex;

      if (actualColumnIndex < 0) {
        // Sorting by ID column
        _sortedRecords.sort((a, b) {
          final aId = a['id'] ?? 0;
          final bId = b['id'] ?? 0;
          return ascending
              ? Comparable.compare(aId, bId)
              : Comparable.compare(bId, aId);
        });
      } else if (actualColumnIndex < visibleColumns.length) {
        final column = visibleColumns[actualColumnIndex];
        _sortedRecords.sort((a, b) {
          final aFields = a['fields'] as Map<String, dynamic>? ?? {};
          final bFields = b['fields'] as Map<String, dynamic>? ?? {};

          final aValue = aFields[column.name];
          final bValue = bFields[column.name];

          // Handle null values
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return ascending ? 1 : -1;
          if (bValue == null) return ascending ? -1 : 1;

          // Sort based on type
          try {
            switch (column.type) {
              case 'numeric':
              case 'Numeric':
              case 'Int':
              case 'integer':
                final aNum = num.tryParse(aValue.toString()) ?? 0;
                final bNum = num.tryParse(bValue.toString()) ?? 0;
                return ascending
                    ? aNum.compareTo(bNum)
                    : bNum.compareTo(aNum);

              case 'date':
              case 'Date':
                try {
                  final aDate = DateTime.parse(aValue.toString());
                  final bDate = DateTime.parse(bValue.toString());
                  return ascending
                      ? aDate.compareTo(bDate)
                      : bDate.compareTo(aDate);
                } catch (_) {
                  return ascending
                      ? aValue.toString().compareTo(bValue.toString())
                      : bValue.toString().compareTo(aValue.toString());
                }

              default:
                return ascending
                    ? aValue.toString().compareTo(bValue.toString())
                    : bValue.toString().compareTo(aValue.toString());
            }
          } catch (_) {
            return 0;
          }
        });
      }

      _currentPage = 0; // Reset to first page after sorting
      _applyFilters(); // Re-apply filters after sorting
    });
  }

  List<Map<String, dynamic>> _getCurrentPageRecords() {
    if (widget.rowsPerPage == null) {
      return _filteredRecords;
    }

    final startIndex = _currentPage * widget.rowsPerPage!;
    final endIndex = (startIndex + widget.rowsPerPage!).clamp(0, _filteredRecords.length);

    if (startIndex >= _filteredRecords.length) {
      return [];
    }

    return _filteredRecords.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    if (widget.rowsPerPage == null) return 1;
    return (_filteredRecords.length / widget.rowsPerPage!).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      // Get visible column labels for skeleton
      final visibleColumns = widget.columns.where((col) => col.visible).toList();
      final columnLabels = visibleColumns.map((col) => col.label).toList();

      return DataTableSkeletonLoader(
        rowCount: widget.rowsPerPage ?? 8,
        columnLabels: columnLabels,
      );
    }

    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${widget.error}'),
          ],
        ),
      );
    }

    if (widget.records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No records found'),
          ],
        ),
      );
    }

    final visibleColumns = widget.columns.where((col) => col.visible).toList();
    final pageRecords = _getCurrentPageRecords();

    // Build columns for DataTable
    final dataColumns = <DataColumn>[
      if (widget.showIdColumn)
        DataColumn(
          label: const Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
          onSort: widget.enableSorting ? (columnIndex, ascending) {
            _sortData(columnIndex, ascending);
          } : null,
        ),
      ...visibleColumns.asMap().entries.map(
        (entry) {
          final index = entry.key + (widget.showIdColumn ? 1 : 0);
          final col = entry.value;
          final hasFilter = _activeFilters.any((f) => f.columnName == col.name);

          return DataColumn(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  col.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showFilterDialog(col),
                  child: Icon(
                    hasFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
                    size: 16,
                    color: hasFilter ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                ),
              ],
            ),
            onSort: widget.enableSorting && col.sortable
                ? (columnIndex, ascending) {
                    _sortData(columnIndex, ascending);
                  }
                : null,
          );
        },
      ),
    ];

    // Build rows for DataTable
    final dataRows = pageRecords.map((record) {
      final fields = record['fields'] as Map<String, dynamic>? ?? {};
      final recordId = record['id'];

      return DataRow(
        onSelectChanged: widget.onRowTap != null ? (_) => widget.onRowTap!(record) : null,
        cells: [
          if (widget.showIdColumn)
            DataCell(Text(recordId?.toString() ?? '')),
          ...visibleColumns.map((col) {
            final value = fields[col.name];
            return DataCell(
              _buildCellWidget(value, col.type),
            );
          }),
        ],
      );
    }).toList();

    return Column(
      children: [
        // Active filters display
        if (_activeFilters.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._activeFilters.map((filter) {
                  return Chip(
                    avatar: const Icon(Icons.filter_alt, size: 16),
                    label: Text(
                      filter.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeFilter(filter),
                  );
                }),
                // Clear all button
                ActionChip(
                  avatar: const Icon(Icons.clear_all, size: 16),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: _clearAllFilters,
                ),
              ],
            ),
          ),

        // Record count with filter info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Text(
                _activeFilters.isEmpty
                    ? 'Showing ${_filteredRecords.length} records'
                    : 'Showing ${_filteredRecords.length} of ${widget.records.length} records',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: dataColumns,
                rows: dataRows,
                showCheckboxColumn: false,
                horizontalMargin: 16,
                columnSpacing: 24,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
              ),
            ),
          ),
        ),

        // Pagination controls
        if (widget.rowsPerPage != null && _totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page),
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage = 0)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page),
                      onPressed: _currentPage < _totalPages - 1
                          ? () => setState(() => _currentPage = _totalPages - 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCellWidget(dynamic value, String? type) {
    if (value == null) {
      return const Text('—');
    }

    // Image preview for image URLs or data URLs
    if (type == 'file' || type == 'image') {
      final valueStr = value.toString();
      if (valueStr.startsWith('data:image') ||
          valueStr.endsWith('.jpg') ||
          valueStr.endsWith('.jpeg') ||
          valueStr.endsWith('.png') ||
          valueStr.endsWith('.gif')) {
        return SizedBox(
          height: 40,
          child: Image.network(
            valueStr,
            errorBuilder: (context, error, stackTrace) =>
                Text(_formatValue(value, type)),
          ),
        );
      }
    }

    return Text(
      _formatValue(value, type),
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatValue(dynamic value, String? type) {
    if (value == null) return '—';

    switch (type) {
      case 'boolean':
      case 'Bool':
        return value.toString() == 'true' || value == true ? '✓' : '✗';

      case 'date':
      case 'Date':
        try {
          final date = DateTime.parse(value.toString());
          return DateFormat('yyyy-MM-dd').format(date);
        } catch (_) {
          return value.toString();
        }

      case 'datetime':
        try {
          final date = DateTime.parse(value.toString());
          return DateFormat('yyyy-MM-dd HH:mm').format(date);
        } catch (_) {
          return value.toString();
        }

      case 'numeric':
      case 'Numeric':
      case 'Int':
      case 'integer':
        return value.toString();

      case 'currency':
        final num? numValue = num.tryParse(value.toString());
        if (numValue != null) {
          return '\$${numValue.toStringAsFixed(2)}';
        }
        return value.toString();

      case 'file':
      case 'image':
        // Return filename or 'Attached' if it's a data URL
        final valueStr = value.toString();
        if (valueStr.startsWith('data:')) {
          return '📎 Attached';
        }
        return valueStr.split('/').last; // Get filename from URL

      default:
        return value.toString();
    }
  }
}
