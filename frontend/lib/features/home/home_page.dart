import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.pagePadding(context);
    final titleStyle = isMobile ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium;

    return Padding(
      padding: padding,
      child: ListView(
        children: [
          Text(
            'Panel principal',
            style: titleStyle?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Consulta ligas, genera fixtures y gestiona resultados desde un único lugar.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = isMobile ? constraints.maxWidth : 220.0;
              final spacing = isMobile ? 12.0 : 16.0;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _SummaryCard(title: 'Ligas activas', value: '0', width: cardWidth),
                  _SummaryCard(title: 'Torneos en curso', value: '0', width: cardWidth),
                  _SummaryCard(title: 'Partidos confirmados', value: '0', width: cardWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.width,
  });

  final String title;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
