import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/rbs_theme.dart';
import '../widgets/rbs_drawer.dart';
import '../core/widgets/rbs_components.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('InduScore')),
      drawer: const RBSDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RBSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const RBSHeadline(text: 'InduScore', level: RBSHeadlineLevel.h1),
            const SizedBox(height: RBSSpacing.xs),
            Text(
              'Berufsschule für Industrieelektronik',
              style: RBSTypography.bodyLarge.copyWith(
                color: RBSColors.textOnLight.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: RBSSpacing.xl),

            // Feature Cards (responsive grid)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 520;
                final crossAxisCount = isNarrow ? 2 : 3;
                final spacing = RBSSpacing.md;
                final aspectRatio = isNarrow ? 1.1 : 1.15;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                  children: [
                    _buildFeatureCard(
                      context,
                      icon: Icons.school_outlined,
                      title: 'Klassen',
                      subtitle: 'Verwalten',
                      color: RBSColors.dynamicRed,
                      onTap: () {
                        context.go('/klassen');
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.person_outline,
                      title: 'Schüler',
                      subtitle: 'Verwalten',
                      color: RBSColors.growingElder,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Schülerverwaltung kommt in v1.0.0'),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.book_outlined,
                      title: 'Fächer',
                      subtitle: 'Organisieren',
                      color: RBSColors.courtGreen,
                      onTap: () {
                        context.go('/faecher');
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.assignment_outlined,
                      title: 'Noten',
                      subtitle: 'Eintragen',
                      color: RBSColors.dynamicRed,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Noteneingabe kommt in v1.0.0'),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return RBSCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final iconSize = (maxWidth * 0.32).clamp(32, 52).toDouble();
          final titleSize = (maxWidth * 0.14).clamp(15, 19).toDouble();
          final subtitleSize = (maxWidth * 0.11).clamp(12, 15).toDouble();

          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(RBSSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: iconSize, color: color),
                  const SizedBox(height: RBSSpacing.xs),
                  Text(
                    title,
                    style: RBSTypography.h4.copyWith(fontSize: titleSize),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: RBSSpacing.xs),
                  Text(
                    subtitle,
                    style: RBSTypography.bodySmall.copyWith(
                      fontSize: subtitleSize,
                      color: RBSColors.textOnLight.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
