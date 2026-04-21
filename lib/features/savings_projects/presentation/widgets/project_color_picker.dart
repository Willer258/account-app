import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Predefined colors for quick selection.
const _presetColors = [
  Color(0xFFE53935), // Red
  Color(0xFFFF9800), // Orange
  Color(0xFFFFEB3B), // Yellow
  Color(0xFF4CAF50), // Green
  Color(0xFF2196F3), // Blue
  Color(0xFF9C27B0), // Purple
  Color(0xFFE91E63), // Pink
  Color(0xFF607D8B), // Grey
];

/// Color picker widget for savings projects.
///
/// Shows preset colors and allows custom color selection.
class ProjectColorPicker extends StatefulWidget {
  const ProjectColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  @override
  State<ProjectColorPicker> createState() => _ProjectColorPickerState();
}

class _ProjectColorPickerState extends State<ProjectColorPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.selectedColor;
  }

  @override
  void didUpdateWidget(ProjectColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      _currentColor = widget.selectedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleur',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.revolutOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Preset colors
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ..._presetColors.map((color) => _ColorCircle(
                  color: color,
                  isSelected: _isSameColor(color, _currentColor),
                  onTap: () => _selectColor(color),
                )),
            // Custom color button
            _CustomColorButton(
              currentColor: _currentColor,
              isSelected: !_presetColors.any((c) => _isSameColor(c, _currentColor)),
              onColorSelected: _selectColor,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Preview
        _ColorPreview(color: _currentColor),
      ],
    );
  }

  void _selectColor(Color color) {
    setState(() {
      _currentColor = color;
    });
    widget.onColorChanged(color);
  }

  bool _isSameColor(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}

/// Individual color circle for selection.
class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.revolutOnDark : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: _getContrastColor(color),
                size: 20,
              )
            : null,
      ),
    );
  }

  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

/// Button to open custom color picker.
class _CustomColorButton extends StatelessWidget {
  const _CustomColorButton({
    required this.currentColor,
    required this.isSelected,
    required this.onColorSelected,
  });

  final Color currentColor;
  final bool isSelected;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const SweepGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.revolutOnDark : Colors.transparent,
            width: 3,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.colorize,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdvancedColorPicker(
        initialColor: currentColor,
        onColorSelected: (color) {
          Navigator.pop(context);
          onColorSelected(color);
        },
      ),
    );
  }
}

/// Advanced color picker with HSL sliders.
class _AdvancedColorPicker extends StatefulWidget {
  const _AdvancedColorPicker({
    required this.initialColor,
    required this.onColorSelected,
  });

  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  @override
  State<_AdvancedColorPicker> createState() => _AdvancedColorPickerState();
}

class _AdvancedColorPickerState extends State<_AdvancedColorPicker> {
  late HSLColor _hslColor;

  @override
  void initState() {
    super.initState();
    _hslColor = HSLColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final color = _hslColor.toColor();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.revolutSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                'Couleur personnalisée',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.revolutOnDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Color preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Hue slider
              _ColorSlider(
                label: 'Teinte',
                value: _hslColor.hue,
                max: 360,
                gradient: LinearGradient(
                  colors: List.generate(
                    7,
                    (i) => HSLColor.fromAHSL(1, i * 60.0, 1, 0.5).toColor(),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _hslColor = _hslColor.withHue(value);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Saturation slider
              _ColorSlider(
                label: 'Saturation',
                value: _hslColor.saturation * 100,
                max: 100,
                gradient: LinearGradient(
                  colors: [
                    HSLColor.fromAHSL(1, _hslColor.hue, 0, _hslColor.lightness)
                        .toColor(),
                    HSLColor.fromAHSL(1, _hslColor.hue, 1, _hslColor.lightness)
                        .toColor(),
                  ],
                ),
                onChanged: (value) {
                  setState(() {
                    _hslColor = _hslColor.withSaturation(value / 100);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Lightness slider
              _ColorSlider(
                label: 'Luminosité',
                value: _hslColor.lightness * 100,
                max: 100,
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    HSLColor.fromAHSL(1, _hslColor.hue, _hslColor.saturation, 0.5)
                        .toColor(),
                    Colors.white,
                  ],
                ),
                onChanged: (value) {
                  setState(() {
                    _hslColor = _hslColor.withLightness(value / 100);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onColorSelected(color),
                  child: const Text('Confirmer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slider for color values.
class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.gradient,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final Gradient gradient;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.revolutOnDarkMuted,
              ),
            ),
            Text(
              value.round().toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.revolutOnDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 24,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 24,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 2,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Preview card showing how the color will look.
class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '🎯',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aperçu du projet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.revolutOnDark,
                  ),
                ),
                const SizedBox(height: 4),
                // Mini progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.revolutBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.65,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '65%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
