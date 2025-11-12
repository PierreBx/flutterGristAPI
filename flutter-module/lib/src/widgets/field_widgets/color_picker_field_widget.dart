import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// A color picker field widget for selecting colors.
///
/// Features:
/// - Material color picker
/// - HSV color picker
/// - RGB sliders
/// - Hex color input
/// - Color swatches
/// - Recently used colors
/// - Alpha channel support
class ColorPickerFieldWidget extends StatefulWidget {
  /// Field label
  final String label;

  /// Initial color value (hex string or Color)
  final dynamic value;

  /// Callback when color changes
  final ValueChanged<String>? onChanged;

  /// Whether the field is read-only
  final bool readOnly;

  /// Picker type
  final ColorPickerType pickerType;

  /// Whether to show alpha channel
  final bool showAlpha;

  /// Predefined color swatches
  final List<Color>? colorSwatches;

  /// Whether to show recently used colors
  final bool showRecentColors;

  const ColorPickerFieldWidget({
    Key? key,
    required this.label,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.pickerType = ColorPickerType.material,
    this.showAlpha = false,
    this.colorSwatches,
    this.showRecentColors = true,
  }) : super(key: key);

  @override
  State<ColorPickerFieldWidget> createState() => _ColorPickerFieldWidgetState();
}

class _ColorPickerFieldWidgetState extends State<ColorPickerFieldWidget> {
  late Color _selectedColor;
  final List<Color> _recentColors = [];

  @override
  void initState() {
    super.initState();
    _selectedColor = _parseColor(widget.value);
  }

  @override
  void didUpdateWidget(ColorPickerFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _selectedColor = _parseColor(widget.value);
      });
    }
  }

  Color _parseColor(dynamic value) {
    if (value == null) return Colors.blue;

    if (value is Color) return value;

    if (value is String) {
      try {
        final hex = value.replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (e) {
        // Invalid hex, return default
      }
    }

    return Colors.blue;
  }

  String _colorToHex(Color color, {bool withAlpha = false}) {
    if (withAlpha) {
      return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    } else {
      return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    }
  }

  void _showColorPicker() async {
    Color? pickedColor;

    await showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _selectedColor;

        return AlertDialog(
          title: Text('Select ${widget.label}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color picker based on type
                _buildPicker(tempColor, (color) {
                  tempColor = color;
                }),

                SizedBox(height: 16),

                // Hex input
                TextField(
                  controller: TextEditingController(
                    text: _colorToHex(tempColor, withAlpha: widget.showAlpha),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Hex Code',
                    prefixText: '#',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    try {
                      final color = _parseColor(value);
                      tempColor = color;
                    } catch (e) {
                      // Invalid hex
                    }
                  },
                ),

                // Color swatches
                if (widget.colorSwatches != null && widget.colorSwatches!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Swatches',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.colorSwatches!.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            tempColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tempColor == color
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              width: tempColor == color ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Recent colors
                if (widget.showRecentColors && _recentColors.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Recent Colors',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentColors.take(8).map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            tempColor = color;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                pickedColor = tempColor;
                Navigator.of(context).pop();
              },
              child: Text('Select'),
            ),
          ],
        );
      },
    );

    if (pickedColor != null) {
      setState(() {
        _selectedColor = pickedColor!;

        // Add to recent colors
        if (!_recentColors.contains(pickedColor!)) {
          _recentColors.insert(0, pickedColor!);
          if (_recentColors.length > 12) {
            _recentColors.removeLast();
          }
        }
      });

      if (widget.onChanged != null) {
        widget.onChanged!(_colorToHex(_selectedColor, withAlpha: widget.showAlpha));
      }
    }
  }

  Widget _buildPicker(Color currentColor, ValueChanged<Color> onColorChanged) {
    switch (widget.pickerType) {
      case ColorPickerType.material:
        return MaterialPicker(
          pickerColor: currentColor,
          onColorChanged: onColorChanged,
          enableLabel: true,
        );

      case ColorPickerType.block:
        return BlockPicker(
          pickerColor: currentColor,
          onColorChanged: onColorChanged,
        );

      case ColorPickerType.hsv:
        return ColorPicker(
          pickerColor: currentColor,
          onColorChanged: onColorChanged,
          pickerAreaHeightPercent: 0.8,
          enableAlpha: widget.showAlpha,
          displayThumbColor: true,
          paletteType: PaletteType.hsvWithHue,
        );

      case ColorPickerType.rgb:
        return ColorPicker(
          pickerColor: currentColor,
          onColorChanged: onColorChanged,
          pickerAreaHeightPercent: 0.8,
          enableAlpha: widget.showAlpha,
          displayThumbColor: true,
          paletteType: PaletteType.rgb,
        );
    }
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

        // Color display and picker button
        InkWell(
          onTap: widget.readOnly ? null : _showColorPicker,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Color preview
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                SizedBox(width: 16),

                // Color info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _colorToHex(_selectedColor, withAlpha: widget.showAlpha),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'RGB: ${_selectedColor.red}, ${_selectedColor.green}, ${_selectedColor.blue}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Picker icon
                if (!widget.readOnly)
                  Icon(Icons.color_lens, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Type of color picker
enum ColorPickerType {
  material,
  block,
  hsv,
  rgb,
}

/// Compact color picker showing just the color swatch
class CompactColorPickerWidget extends StatelessWidget {
  final String label;
  final dynamic value;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const CompactColorPickerWidget({
    Key? key,
    required this.label,
    this.value,
    this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  Color _parseColor(dynamic value) {
    if (value == null) return Colors.blue;
    if (value is Color) return value;

    if (value is String) {
      try {
        final hex = value.replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (e) {
        // Invalid hex
      }
    }

    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(value);

    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(width: 12),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }
}

/// Predefined color swatches
class ColorSwatches {
  static const List<Color> material = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  static const List<Color> basic = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.black,
    Colors.white,
  ];

  static const List<Color> pastel = [
    Color(0xFFFFB3BA),
    Color(0xFFFFDFBA),
    Color(0xFFFFFFBA),
    Color(0xFFBAFFC9),
    Color(0xFFBAE1FF),
    Color(0xFFE0BBE4),
    Color(0xFFFEC8D8),
    Color(0xFFD4F1F4),
  ];
}
