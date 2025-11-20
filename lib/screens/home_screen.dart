import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notentool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Show user profile / settings
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.grade,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Willkommen bei Notentool',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Ihre Notenverwaltung',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureCard(
                  context,
                  icon: Icons.person,
                  title: 'Schüler',
                  subtitle: 'Verwalten',
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.book,
                  title: 'Fächer',
                  subtitle: 'Organisieren',
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.assignment,
                  title: 'Noten',
                  subtitle: 'Eintragen',
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Statistiken',
                  subtitle: 'Analysieren',
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Quick add grade
        },
        icon: const Icon(Icons.add),
        label: const Text('Neue Note'),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to feature
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
