/// Berufe an der Berufsschule fÃ¼r Industrieelektronik
enum Beruf {
  ie('IE', 'Industrieelektroniker'),
  eat('EAT', 'Elektroniker für Automatisierungstechnik'),
  ebt('EBT', 'Elektroniker für Betriebstechnik'),
  egs('EGS', 'Elektroniker für Geräte und Systeme');

  final String code;
  final String name;

  const Beruf(this.code, this.name);

  static Beruf fromCode(String code) {
    return Beruf.values.firstWhere(
      (b) => b.code == code,
      orElse: () => throw ArgumentError('Invalid Beruf code: $code'),
    );
  }
}

/// Schuljahr (z.B. "2024/25")
class Schuljahr {
  final int startYear;
  final int endYear;

  const Schuljahr(this.startYear, this.endYear);

  factory Schuljahr.fromString(String schuljahr) {
    final value = schuljahr.trim();
    final match = RegExp(r'^(\d{4})[/-]?(\d{2,4})$').firstMatch(value);
    if (match == null) {
      throw const FormatException('Schuljahr muss z.B. 2024/25 sein');
    }
    final start = int.parse(match.group(1)!);
    final endRaw = match.group(2)!;
    final end = endRaw.length == 2
        ? int.parse('${start.toString().substring(0, 2)}$endRaw')
        : int.parse(endRaw);

    return Schuljahr(start, end);
  }

  /// Erstellt Schuljahr aus aktuellem Datum
  /// (Aug-Dez = aktuelles Jahr, Jan-Jul = Vorjahr)
  factory Schuljahr.current() {
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    final endYear = startYear + 1;
    return Schuljahr(startYear, endYear);
  }

  @override
  String toString() => '$startYear/${endYear.toString().substring(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schuljahr &&
          runtimeType == other.runtimeType &&
          startYear == other.startYear &&
          endYear == other.endYear;

  @override
  int get hashCode => startYear.hashCode ^ endYear.hashCode;
}

/// Zeitgruppe fÃ¼r Nachschreiber-Management
enum Zeitgruppe {
  eins(1, 'Zeitgruppe 1'),
  zwei(2, 'Zeitgruppe 2'),
  drei(3, 'Zeitgruppe 3'); // Keine Umlaute nötig, aber falls vorhanden, hier korrigieren

  final int nummer;
  final String name;

  const Zeitgruppe(this.nummer, this.name);

  static Zeitgruppe fromNummer(int nummer) {
    return Zeitgruppe.values.firstWhere(
      (z) => z.nummer == nummer,
      orElse: () => throw ArgumentError('Invalid Zeitgruppe: $nummer'),
    );
  }
}
