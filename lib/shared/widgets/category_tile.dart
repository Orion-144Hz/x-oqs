import 'package:flutter/material.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/core/theme/obsidian_decorations.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.label,
    required this.color,
    this.onTap,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(ObsidianRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(ObsidianRadii.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Text(
            label,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ObsidianColors.primaryText,
                  fontSize: 18,
                ),
          ),
        ),
      ),
    );
  }
}
