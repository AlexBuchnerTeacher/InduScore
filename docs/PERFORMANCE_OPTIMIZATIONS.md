# Performance Optimizations

Dokumentation aller Performance-Optimierungen in InduScore.

## Übersicht

| Optimierung | Version | Impact |
|-------------|---------|--------|
| Lazy Loading Routes | v0.22.0 | Schnellerer Initial Load |
| DashboardStatsProvider | v0.22.0 | Weniger Widget-Rebuilds |
| NoTransitionPage | v0.22.0 | Schnellere Navigation |
| PaginatedFirestoreList | v0.19.0 | Effiziente Listen-Darstellung |

---

## 1. Lazy Loading für Routes (v0.22.0)

### Problem
Alle Screens wurden beim App-Start initialisiert, auch wenn sie nie besucht werden.

### Lösung
`pageBuilder` statt `builder` in GoRouter:

```dart
// Vorher - Widget wird sofort gebaut
GoRoute(
  path: '/klassen',
  builder: (context, state) => const KlassenScreen(),
)

// Nachher - Widget wird erst bei Navigation gebaut
GoRoute(
  path: '/klassen',
  pageBuilder: (context, state) => const NoTransitionPage(
    child: KlassenScreen(),
  ),
)
```

### Vorteile
- Schnellerer App-Start
- Geringerer Speicherverbrauch
- Widgets werden on-demand erstellt

### Dateien
- `lib/main.dart` - Alle 17 Routes nutzen `pageBuilder`

---

## 2. DashboardStatsProvider (v0.22.0)

### Problem
Dashboard watch't 4 separate Provider mit vollen Listen nur für Counts:
```dart
final klassenAsync = ref.watch(klassenProvider);      // List<Klasse>
final studentsAsync = ref.watch(studentsProvider);    // List<Student>
final subjectsAsync = ref.watch(subjectsProvider);    // List<Subject>
final gradesAsync = ref.watch(gradesProvider);        // List<Grade>
```

Jede Änderung an einer Liste → kompletter Dashboard-Rebuild.

### Lösung
Computed Provider der nur Counts liefert:

```dart
class DashboardStats {
  final int klassenCount;
  final int studentsCount;
  final int subjectsCount;
  final int gradesCount;
  final bool isLoading;
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  // Berechnet Counts aus den Stream-Providern
  return DashboardStats(
    klassenCount: ref.watch(klassenProvider).value?.length ?? 0,
    // ...
  );
});
```

### Vorteile
- Widget rebuilt nur wenn Counts sich ändern
- `DashboardStatisticsGrid` kann `const` sein
- Weniger Speicher-Allokationen

### Dateien
- `lib/providers/app_providers.dart` - `DashboardStats` Klasse + Provider
- `lib/features/dashboard/widgets/statistics_cards.dart` - Nutzt Provider intern

---

## 3. NoTransitionPage (v0.22.0)

### Problem
Standard-Page-Transitions kosten Zeit und CPU.

### Lösung
`NoTransitionPage` für alle Routes:

```dart
pageBuilder: (context, state) => const NoTransitionPage(
  child: KlassenScreen(),
)
```

### Vorteile
- Sofortige Navigation ohne Animation
- Weniger CPU-Last
- Bessere UX für Web-Anwendung

---

## 4. PaginatedFirestoreList (v0.19.0)

### Problem
Große Listen (z.B. 500+ Schüler) werden komplett geladen.

### Lösung
Generisches Widget mit Pagination:

```dart
PaginatedFirestoreList<Student>(
  query: firestore.collection('students').orderBy('name'),
  pageSize: 25,
  itemBuilder: (student) => StudentCard(student: student),
)
```

### Features
- Lädt nur sichtbare Items + Buffer
- Infinite Scroll
- Loading-Indikatoren
- Generisch für alle Firestore-Collections

### Dateien
- `lib/shared/widgets/paginated_firestore_list.dart`

---

## Lighthouse Scores

### Ziel-Scores
| Metrik | Ziel | Status |
|--------|------|--------|
| Performance | >80 | 🎯 |
| Accessibility | >90 | ✅ |
| Best Practices | >90 | ✅ |
| SEO | >80 | ✅ |

### Messungen
```bash
# Chrome DevTools > Lighthouse
# Oder: npm install -g lighthouse
lighthouse https://your-app.web.app --view
```

---

## Best Practices

### Provider-Watches
```dart
// ❌ Schlecht - watched ganze Liste
final students = ref.watch(studentsProvider);
final count = students.value?.length ?? 0;

// ✅ Gut - computed Provider für Count
final count = ref.watch(studentCountProvider);
```

### Widget-Konstanz
```dart
// ❌ Schlecht - neues Widget bei jedem Build
DashboardStatisticsGrid(
  klassenAsync: klassenAsync,
)

// ✅ Gut - const Widget, holt Daten selbst
const DashboardStatisticsGrid()
```

### Lazy Widgets
```dart
// ❌ Schlecht - Widget immer gebaut
Container(child: ExpensiveWidget())

// ✅ Gut - Widget nur bei Bedarf
if (showExpensive) ExpensiveWidget()
```

---

## Weitere Optimierungsmöglichkeiten

### Noch nicht implementiert:
1. **Deferred Loading** - `deferred as` für große Libraries
2. **Image Caching** - CachedNetworkImage für Profilbilder
3. **Firestore Caching** - persistenceEnabled: true
4. **Service Worker** - Offline-First Caching

---

## Referenzen

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Riverpod Performance](https://riverpod.dev/docs/essentials/performance_optimizations)
- [go_router Lazy Loading](https://pub.dev/packages/go_router)
