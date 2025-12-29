import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/rbs_theme.dart';
import '../../../models/student.dart';

/// Statistik-Kachel für Dashboard
class DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const DashboardStatCard({
    required this.icon, required this.label, required this.value, required this.color, required this.onTap, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid mit 4 Statistik-Kacheln (responsive)
class DashboardStatisticsGrid extends ConsumerWidget {
  final AsyncValue klassenAsync;
  final AsyncValue studentsAsync;
  final AsyncValue subjectsAsync;
  final AsyncValue gradesAsync;

  const DashboardStatisticsGrid({
    required this.klassenAsync, required this.studentsAsync, required this.subjectsAsync, required this.gradesAsync, super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        final double childAspectRatio;
        
        if (width < 400) {
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        } else if (width < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.8;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.5;
        }
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            DashboardStatCard(
              icon: Icons.school,
              label: 'Klassen',
              value: klassenAsync.when(
                data: (data) => '${(data as List).length}',
                loading: () => '...',
                error: (e, s) => '-',
              ),
              color: RBSColors.dynamicRed,
              onTap: () => context.go('/klassen'),
            ),
            DashboardStatCard(
              icon: Icons.people,
              label: 'Schüler',
              value: studentsAsync.when(
                data: (data) => '${(data as List<dynamic>).cast<Student>().where((s) => s.isAktiv).length}',
                loading: () => '...',
                error: (e, s) => '-',
              ),
              color: RBSColors.courtGreen,
              onTap: () => context.go('/schueler'),
            ),
            DashboardStatCard(
              icon: Icons.book,
              label: 'Fächer',
              value: subjectsAsync.when(
                data: (data) => '${(data as List).length}',
                loading: () => '...',
                error: (e, s) => '-',
              ),
              color: RBSColors.growingElder,
              onTap: () => context.go('/faecher'),
            ),
            DashboardStatCard(
              icon: Icons.grade,
              label: 'Noten',
              value: gradesAsync.when(
                data: (data) => '${(data as List).length}',
                loading: () => '...',
                error: (e, s) => '-',
              ),
              color: const Color(0xFF2E7BB5),
              onTap: () => context.go('/leistungsnachweise'),
            ),
          ],
        );
      },
    );
  }
}
