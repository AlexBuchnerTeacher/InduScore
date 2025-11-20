/// Berufe an der Berufsschule für Industrieelektronik
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

  Schuljahr(this.startYear, this.endYear);

  Schuljahr.fromString(String schuljahr)
    : startYear = int.parse(schuljahr.split('/')[0]),
      endYear = int.parse(schuljahr.split('/')[1]);

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

/// Zeitgruppe für Nachschreiber-Management
enum Zeitgruppe {
  eins(1, 'Zeitgruppe 1'),
  zwei(2, 'Zeitgruppe 2'),
  drei(3, 'Zeitgruppe 3');

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
