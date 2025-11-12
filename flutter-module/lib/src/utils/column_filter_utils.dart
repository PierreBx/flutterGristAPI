import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Filter operator types
enum FilterOperator {
  contains,
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  between,
  startsWith,
  endsWith,
  isTrue,
  isFalse,
  isNull,
  isNotNull,
  inList,
}

/// Represents a filter on a single column
class ColumnFilter {
  final String columnName;
  final String columnLabel;
  final FilterOperator operator;
  final dynamic value;
  final dynamic value2; // For 'between' operator
  final String? columnType;

  const ColumnFilter({
    required this.columnName,
    required this.columnLabel,
    required this.operator,
    this.value,
    this.value2,
    this.columnType,
  });

  /// Returns a human-readable description of this filter
  String get description {
    switch (operator) {
      case FilterOperator.contains:
        return '$columnLabel contains "$value"';
      case FilterOperator.equals:
        return '$columnLabel = $value';
      case FilterOperator.notEquals:
        return '$columnLabel ≠ $value';
      case FilterOperator.greaterThan:
        return '$columnLabel > $value';
      case FilterOperator.lessThan:
        return '$columnLabel < $value';
      case FilterOperator.greaterThanOrEqual:
        return '$columnLabel ≥ $value';
      case FilterOperator.lessThanOrEqual:
        return '$columnLabel ≤ $value';
      case FilterOperator.between:
        return '$columnLabel between $value and $value2';
      case FilterOperator.startsWith:
        return '$columnLabel starts with "$value"';
      case FilterOperator.endsWith:
        return '$columnLabel ends with "$value"';
      case FilterOperator.isTrue:
        return '$columnLabel is true';
      case FilterOperator.isFalse:
        return '$columnLabel is false';
      case FilterOperator.isNull:
        return '$columnLabel is empty';
      case FilterOperator.isNotNull:
        return '$columnLabel is not empty';
      case FilterOperator.inList:
        return '$columnLabel in [${(value as List).join(', ')}]';
    }
  }

  /// Checks if a record matches this filter
  bool matches(Map<String, dynamic> record) {
    final fields = record['fields'] as Map<String, dynamic>? ?? {};
    final fieldValue = fields[columnName];

    switch (operator) {
      case FilterOperator.isNull:
        return fieldValue == null || fieldValue.toString().isEmpty;
      case FilterOperator.isNotNull:
        return fieldValue != null && fieldValue.toString().isNotEmpty;
      case FilterOperator.isTrue:
        return fieldValue == true || fieldValue.toString().toLowerCase() == 'true';
      case FilterOperator.isFalse:
        return fieldValue == false || fieldValue.toString().toLowerCase() == 'false';
      default:
        break;
    }

    if (fieldValue == null) return false;

    switch (operator) {
      case FilterOperator.contains:
        return fieldValue.toString().toLowerCase().contains(
          value.toString().toLowerCase(),
        );

      case FilterOperator.equals:
        return _compareValues(fieldValue, value, columnType) == 0;

      case FilterOperator.notEquals:
        return _compareValues(fieldValue, value, columnType) != 0;

      case FilterOperator.greaterThan:
        return _compareValues(fieldValue, value, columnType) > 0;

      case FilterOperator.lessThan:
        return _compareValues(fieldValue, value, columnType) < 0;

      case FilterOperator.greaterThanOrEqual:
        return _compareValues(fieldValue, value, columnType) >= 0;

      case FilterOperator.lessThanOrEqual:
        return _compareValues(fieldValue, value, columnType) <= 0;

      case FilterOperator.between:
        final comp1 = _compareValues(fieldValue, value, columnType);
        final comp2 = _compareValues(fieldValue, value2, columnType);
        return comp1 >= 0 && comp2 <= 0;

      case FilterOperator.startsWith:
        return fieldValue.toString().toLowerCase().startsWith(
          value.toString().toLowerCase(),
        );

      case FilterOperator.endsWith:
        return fieldValue.toString().toLowerCase().endsWith(
          value.toString().toLowerCase(),
        );

      case FilterOperator.inList:
        final list = value as List;
        return list.contains(fieldValue.toString());

      default:
        return true;
    }
  }

  int _compareValues(dynamic a, dynamic b, String? type) {
    if (type == 'numeric' || type == 'integer' || type == 'Numeric' || type == 'Int') {
      final aNum = num.tryParse(a.toString()) ?? 0;
      final bNum = num.tryParse(b.toString()) ?? 0;
      return aNum.compareTo(bNum);
    }

    if (type == 'date' || type == 'datetime' || type == 'Date') {
      try {
        final aDate = DateTime.parse(a.toString());
        final bDate = DateTime.parse(b.toString());
        return aDate.compareTo(bDate);
      } catch (_) {
        return a.toString().compareTo(b.toString());
      }
    }

    return a.toString().compareTo(b.toString());
  }
}

/// Dialog for creating/editing column filters
class ColumnFilterDialog extends StatefulWidget {
  final String columnName;
  final String columnLabel;
  final String? columnType;
  final List<String>? choices;
  final ColumnFilter? existingFilter;

  const ColumnFilterDialog({
    super.key,
    required this.columnName,
    required this.columnLabel,
    this.columnType,
    this.choices,
    this.existingFilter,
  });

  @override
  State<ColumnFilterDialog> createState() => _ColumnFilterDialogState();
}

class _ColumnFilterDialogState extends State<ColumnFilterDialog> {
  late FilterOperator _selectedOperator;
  final _valueController = TextEditingController();
  final _value2Controller = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedDate2;
  List<String> _selectedChoices = [];

  @override
  void initState() {
    super.initState();

    if (widget.existingFilter != null) {
      _selectedOperator = widget.existingFilter!.operator;
      _valueController.text = widget.existingFilter!.value?.toString() ?? '';
      _value2Controller.text = widget.existingFilter!.value2?.toString() ?? '';

      if (widget.existingFilter!.value is DateTime) {
        _selectedDate = widget.existingFilter!.value as DateTime;
      }
      if (widget.existingFilter!.value2 is DateTime) {
        _selectedDate2 = widget.existingFilter!.value2 as DateTime;
      }
      if (widget.existingFilter!.value is List) {
        _selectedChoices = (widget.existingFilter!.value as List).cast<String>();
      }
    } else {
      _selectedOperator = _getDefaultOperator();
    }
  }

  FilterOperator _getDefaultOperator() {
    switch (widget.columnType?.toLowerCase()) {
      case 'boolean':
      case 'bool':
        return FilterOperator.isTrue;
      case 'numeric':
      case 'integer':
      case 'int':
        return FilterOperator.equals;
      case 'date':
      case 'datetime':
        return FilterOperator.equals;
      case 'choice':
        return FilterOperator.inList;
      default:
        return FilterOperator.contains;
    }
  }

  List<FilterOperator> _getAvailableOperators() {
    switch (widget.columnType?.toLowerCase()) {
      case 'boolean':
      case 'bool':
        return [
          FilterOperator.isTrue,
          FilterOperator.isFalse,
          FilterOperator.isNull,
        ];

      case 'numeric':
      case 'integer':
      case 'int':
        return [
          FilterOperator.equals,
          FilterOperator.notEquals,
          FilterOperator.greaterThan,
          FilterOperator.lessThan,
          FilterOperator.greaterThanOrEqual,
          FilterOperator.lessThanOrEqual,
          FilterOperator.between,
          FilterOperator.isNull,
        ];

      case 'date':
      case 'datetime':
        return [
          FilterOperator.equals,
          FilterOperator.greaterThan,
          FilterOperator.lessThan,
          FilterOperator.between,
          FilterOperator.isNull,
        ];

      case 'choice':
        return [
          FilterOperator.inList,
          FilterOperator.equals,
          FilterOperator.notEquals,
          FilterOperator.isNull,
        ];

      default:
        return [
          FilterOperator.contains,
          FilterOperator.equals,
          FilterOperator.notEquals,
          FilterOperator.startsWith,
          FilterOperator.endsWith,
          FilterOperator.isNull,
          FilterOperator.isNotNull,
        ];
    }
  }

  String _operatorLabel(FilterOperator op) {
    switch (op) {
      case FilterOperator.contains:
        return 'Contains';
      case FilterOperator.equals:
        return 'Equals';
      case FilterOperator.notEquals:
        return 'Not Equals';
      case FilterOperator.greaterThan:
        return 'Greater Than';
      case FilterOperator.lessThan:
        return 'Less Than';
      case FilterOperator.greaterThanOrEqual:
        return 'Greater or Equal';
      case FilterOperator.lessThanOrEqual:
        return 'Less or Equal';
      case FilterOperator.between:
        return 'Between';
      case FilterOperator.startsWith:
        return 'Starts With';
      case FilterOperator.endsWith:
        return 'Ends With';
      case FilterOperator.isTrue:
        return 'Is True';
      case FilterOperator.isFalse:
        return 'Is False';
      case FilterOperator.isNull:
        return 'Is Empty';
      case FilterOperator.isNotNull:
        return 'Is Not Empty';
      case FilterOperator.inList:
        return 'In List';
    }
  }

  Widget _buildValueInput() {
    // Boolean operators don't need value input
    if (_selectedOperator == FilterOperator.isTrue ||
        _selectedOperator == FilterOperator.isFalse ||
        _selectedOperator == FilterOperator.isNull ||
        _selectedOperator == FilterOperator.isNotNull) {
      return const SizedBox.shrink();
    }

    // Choice field with inList operator
    if (_selectedOperator == FilterOperator.inList && widget.choices != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select values:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.choices!.map((choice) {
              final isSelected = _selectedChoices.contains(choice);
              return FilterChip(
                label: Text(choice),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedChoices.add(choice);
                    } else {
                      _selectedChoices.remove(choice);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      );
    }

    // Date fields
    if (widget.columnType == 'date' || widget.columnType == 'datetime') {
      return Column(
        children: [
          ListTile(
            title: Text(
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : 'Select date',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
          if (_selectedOperator == FilterOperator.between)
            ListTile(
              title: Text(
                _selectedDate2 != null
                    ? DateFormat('yyyy-MM-dd').format(_selectedDate2!)
                    : 'Select end date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate2 ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => _selectedDate2 = date);
                }
              },
            ),
        ],
      );
    }

    // Text/numeric fields
    return Column(
      children: [
        TextField(
          controller: _valueController,
          decoration: InputDecoration(
            labelText: 'Value',
            border: const OutlineInputBorder(),
          ),
          keyboardType: (widget.columnType == 'numeric' || widget.columnType == 'integer')
              ? TextInputType.number
              : TextInputType.text,
        ),
        if (_selectedOperator == FilterOperator.between) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _value2Controller,
            decoration: InputDecoration(
              labelText: 'To',
              border: const OutlineInputBorder(),
            ),
            keyboardType: (widget.columnType == 'numeric' || widget.columnType == 'integer')
                ? TextInputType.number
                : TextInputType.text,
          ),
        ],
      ],
    );
  }

  void _applyFilter() {
    dynamic value;
    dynamic value2;

    if (_selectedOperator == FilterOperator.isTrue ||
        _selectedOperator == FilterOperator.isFalse ||
        _selectedOperator == FilterOperator.isNull ||
        _selectedOperator == FilterOperator.isNotNull) {
      // No value needed
    } else if (_selectedOperator == FilterOperator.inList) {
      if (_selectedChoices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one value')),
        );
        return;
      }
      value = _selectedChoices;
    } else if (widget.columnType == 'date' || widget.columnType == 'datetime') {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
        return;
      }
      value = _selectedDate;
      if (_selectedOperator == FilterOperator.between) {
        if (_selectedDate2 == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an end date')),
          );
          return;
        }
        value2 = _selectedDate2;
      }
    } else {
      if (_valueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a value')),
        );
        return;
      }
      value = _valueController.text;
      if (_selectedOperator == FilterOperator.between) {
        if (_value2Controller.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a second value')),
          );
          return;
        }
        value2 = _value2Controller.text;
      }
    }

    final filter = ColumnFilter(
      columnName: widget.columnName,
      columnLabel: widget.columnLabel,
      operator: _selectedOperator,
      value: value,
      value2: value2,
      columnType: widget.columnType,
    );

    Navigator.of(context).pop(filter);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter: ${widget.columnLabel}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<FilterOperator>(
              value: _selectedOperator,
              decoration: const InputDecoration(
                labelText: 'Operator',
                border: OutlineInputBorder(),
              ),
              items: _getAvailableOperators().map((op) {
                return DropdownMenuItem(
                  value: op,
                  child: Text(_operatorLabel(op)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedOperator = value);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildValueInput(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _applyFilter,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _value2Controller.dispose();
    super.dispose();
  }
}
