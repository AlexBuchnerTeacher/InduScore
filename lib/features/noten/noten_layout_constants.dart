/// Layout-Konstanten für die Notenübersicht
/// 
/// Definiert kompakte Spacing-Werte für eine übersichtlichere Darstellung.
/// Issue #47: Notenübersicht kompakter und ruhiger gestalten
library;

/// Spacing-Konstanten für die Notenübersicht
class NotenSpacing {
  // Prevent instantiation
  NotenSpacing._();
  
  /// Extra-kleine Abstände (4px)
  static const double xs = 4.0;
  
  /// Kleine Abstände (6px) - für dichte Tabellen
  static const double sm = 6.0;
  
  /// Medium Abstände (8px) - Standard für kompaktes Layout
  static const double md = 8.0;
  
  /// Größere Abstände (12px) - für Sections
  static const double lg = 12.0;
  
  /// Cell-Padding horizontal
  static const double cellPadH = 6.0;
  
  /// Cell-Padding vertikal
  static const double cellPadV = 4.0;
}

/// Tabellen-Dimensionen für die Notenübersicht
class NotenTableDimensions {
  // Prevent instantiation
  NotenTableDimensions._();
  
  /// Minimale Zeilenhöhe für Daten-Rows (kompakt)
  static const double rowHeightMin = 40.0;
  
  /// Maximale Zeilenhöhe für Daten-Rows (kompakt)
  static const double rowHeightMax = 40.0;
  
  /// Header-Zeilenhöhe
  static const double headerHeight = 48.0;
  
  /// Column-Spacing in DataTables
  static const double columnSpacing = 6.0;
  
  /// Breite für Noten-Dropdown (kompakt)
  static const double noteDropdownWidth = 42.0;
  
  /// Breite für Noten-Dropdown mit Tendenz
  static const double noteDropdownWithTendenzWidth = 55.0;
  
  /// Breite für Schüler-Name Spalte
  static const double nameColumnWidth = 140.0;
  
  /// Breite für LN-Spalten
  static const double lnColumnWidth = 50.0;
  
  /// Breite für Durchschnitt-Spalte
  static const double avgColumnWidth = 45.0;
}

/// Font-Größen für die Notenübersicht
class NotenFontSizes {
  // Prevent instantiation
  NotenFontSizes._();
  
  /// Schülername
  static const double studentName = 13.0;
  
  /// Noten-Wert
  static const double noteValue = 13.0;
  
  /// Header/LN-Name
  static const double header = 11.0;
  
  /// Kürzel (updatedBy)
  static const double kuerzel = 7.0;
  
  /// Durchschnitt
  static const double average = 12.0;
  
  /// Statistik-Footer
  static const double stats = 11.0;
}
