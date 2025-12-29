import 'package:flutter/material.dart';

/// Ein zentrales Listen-Widget für alle Hauptbereiche (Klassen, Schüler, Fächer, Noten, Leistungsnachweise)
class EntityListWidget<T> extends StatelessWidget {
  final List<T> items;
  final String title;
  final IconData icon;
  final Widget Function(T) itemBuilder;
  final VoidCallback? onAdd;
  final List<Widget>? actions;

  const EntityListWidget({
    required this.items, required this.title, required this.icon, required this.itemBuilder, super.key,
    this.onAdd,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        actions: actions,
      ),
      floatingActionButton: onAdd != null
          ? FloatingActionButton(
              onPressed: onAdd,
              child: const Icon(Icons.add),
            )
          : null,
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[400], size: 48),
                  const SizedBox(height: 16),
                  Text('Keine Einträge vorhanden', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => itemBuilder(items[index]),
            ),
    );
  }
}
