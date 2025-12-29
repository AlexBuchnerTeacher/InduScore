/// Statistik-Daten für einen Leistungsnachweis
class NotenStatistik {
  final double? durchschnitt;
  final int anzahl;
  final int gesamt;
  final Map<int, int> verteilung;

  NotenStatistik({
    required this.anzahl, required this.gesamt, required this.verteilung, this.durchschnitt,
  });
}
