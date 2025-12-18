import 'package:flutter/material.dart';
import '../theme/rbs_theme.dart';

/// RBS Button - Dynamic Red, Roboto Condensed Bold
/// Verwendung: Primäre Aktionen (Speichern, Anmelden, Hinzufügen)
class RBSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const RBSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: RBSColors.textOnRed,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: RBSSpacing.sm),
                ],
                Text(label),
              ],
            ),
    );
  }
}

/// RBS Tag - Filled, rund, modern
/// Verwendung: Status, Kategorien, Labels
class RBSTag extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;

  const RBSTag({
    super.key,
    required this.label,
    this.color,
    this.onTap,
    this.selected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = color ?? RBSColors.dynamicRed;
    final isLight = selected || onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isLight ? tagColor : tagColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isLight ? Colors.white : tagColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: RBSTypography.tag.copyWith(
                  color: isLight ? Colors.white : tagColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// RBS Card - Weiche Schatten, großer Weißraum
/// Verwendung: Content-Blöcke, Listen-Items, Gruppierungen
class RBSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const RBSCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
        child: Padding(
          padding: padding ?? RBSSpacing.cardPadding,
          child: child,
        ),
      ),
    );
  }
}

/// RBS Headline - Roboto Condensed Bold, linksbündig
/// Verwendung: Seitenüberschriften, Abschnittstitel
class RBSHeadline extends StatelessWidget {
  final String text;
  final RBSHeadlineLevel level;
  final Color? color;
  final TextAlign? textAlign;

  const RBSHeadline({
    super.key,
    required this.text,
    this.level = RBSHeadlineLevel.h2,
    this.color,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle style;
    switch (level) {
      case RBSHeadlineLevel.h1:
        style = RBSTypography.h1;
        break;
      case RBSHeadlineLevel.h2:
        style = RBSTypography.h2;
        break;
      case RBSHeadlineLevel.h3:
        style = RBSTypography.h3;
        break;
      case RBSHeadlineLevel.h4:
        style = RBSTypography.h4;
        break;
    }

    return Text(
      text,
      style: style.copyWith(color: color),
      textAlign: textAlign ?? TextAlign.left, // Linksbündig gemäß Styleguide
    );
  }
}

enum RBSHeadlineLevel { h1, h2, h3, h4 }

/// RBS Input Field - Klar, weiß, Outline bei Fokus
/// Verwendung: Formulare, Eingabefelder
class RBSInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final IconData? prefixIcon;
  final int? maxLines;
  final TextCapitalization textCapitalization;

  const RBSInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: RBSTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}

/// RBS Filter Chip - Rund, filled bei Selection, modern
/// Verwendung: Filter-Leisten, Multi-Select
class RBSFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Color? color;
  final IconData? icon;

  const RBSFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? RBSColors.dynamicRed;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? Colors.white : chipColor),
            const SizedBox(width: 4),
          ],
          Text(label.trim(), textAlign: TextAlign.center),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      backgroundColor: chipColor.withValues(alpha: 0.1),
      selectedColor: chipColor,
      side: BorderSide.none,
      labelStyle: RBSTypography.tag.copyWith(
        color: selected ? Colors.white : chipColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// RBS Action Chip - Rund, für Aktionen
/// Verwendung: Quick Actions, Toggles
class RBSActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool filled;

  const RBSActionChip({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? RBSColors.dynamicRed;

    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: filled ? Colors.white : chipColor),
            const SizedBox(width: 4),
          ],
          Text(label.trim(), textAlign: TextAlign.center),
        ],
      ),
      onPressed: onPressed,
      backgroundColor: filled ? chipColor : chipColor.withValues(alpha: 0.1),
      side: BorderSide.none,
      labelStyle: RBSTypography.tag.copyWith(
        color: filled ? Colors.white : chipColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// RBS Choice Chip - Rund, für Single-Select
/// Verwendung: Radio-artige Auswahl
class RBSChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Color? color;

  const RBSChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? RBSColors.dynamicRed;

    return ChoiceChip(
      label: Text(label.trim(), textAlign: TextAlign.center),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      backgroundColor: chipColor.withValues(alpha: 0.1),
      selectedColor: chipColor,
      side: BorderSide.none,
      labelStyle: RBSTypography.tag.copyWith(
        color: selected ? Colors.white : chipColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// RBS Dialog - Viel Luft, klare Typo
/// Verwendung: Bestätigungen, Formulare, Info-Popups
class RBSDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const RBSDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) =>
          RBSDialog(title: title, content: content, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(RBSSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RBSHeadline(text: title, level: RBSHeadlineLevel.h3),
            const SizedBox(height: RBSSpacing.md),
            content,
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: RBSSpacing.lg),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}

/// RBS Section - Strukturblock mit Überschrift und Inhalt
/// Verwendung: Gruppierung von Content auf Inhalts-Ebene
class RBSSection extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const RBSSection({
    super.key,
    this.title,
    required this.child,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(RBSSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? RBSColors.white,
        borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            RBSHeadline(text: title!, level: RBSHeadlineLevel.h3),
            const SizedBox(height: RBSSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}
