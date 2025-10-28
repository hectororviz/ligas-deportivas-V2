import 'package:flutter/material.dart';

class TableFiltersBar extends StatelessWidget {
  const TableFiltersBar({
    required this.children,
    this.trailing,
    super.key,
  });

  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: children,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}

class TableFilterField extends StatelessWidget {
  const TableFilterField({
    required this.label,
    required this.child,
    this.width,
    super.key,
  });

  final String label;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: child,
          ),
        ),
      ],
    );

    if (width != null) {
      content = SizedBox(width: width, child: content);
    }

    return content;
  }
}

class TableFilterSearchField extends StatelessWidget {
  const TableFilterSearchField({
    required this.controller,
    required this.placeholder,
    required this.showClearButton,
    this.onChanged,
    this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool showClearButton;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(Icons.search, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: theme.textTheme.bodyMedium
                  ?.copyWith(color: iconColor.withOpacity(0.6)),
              border: InputBorder.none,
              isDense: true,
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
        if (showClearButton)
          IconButton(
            tooltip: 'Limpiar búsqueda',
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            color: iconColor,
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
          ),
      ],
    );
  }
}
