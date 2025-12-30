/// Layout-Konstanten für die Notenübersicht
/// 
/// Definiert kompakte Spacing-Werte für eine übersichtlichere Darstellung.
/// Issue #47: Notenübersicht kompakter und ruhiger gestalten
library;

import 'package:flutter/material.dart';

/// Farb-Konstanten für die Notenübersicht
/// 
/// v0.29.0: Reduzierte Farbpalette - nur kritische Noten (5, 6) werden rot
/// hervorgehoben. Andere Noten bleiben neutral für ein ruhigeres Design.
class NotenColors {
  // Prevent instantiation
  NotenColors._();
  
  /// Kritische Note (5) - Rot
  static const Color critical = Color(0xFFD32F2F); // Colors.red[700]
  
  /// Sehr kritische Note (6) - Dunkelrot
  static const Color veryCritical = Color(0xFFB71C1C); // Colors.red[900]
  
  /// Neutrale Note (1-4) - Dunkelgrau
  static const Color neutral = Color(0xFF424242); // Colors.grey[800]
  
  /// Keine Note / Placeholder
  static const Color empty = Color(0xFF9E9E9E); // Colors.grey
  
  /// Hintergrund für Note-Zellen (neutral)
  static const Color cellBackground = Color(0xFFFAFAFA); // Colors.grey[50]
  
  /// Hintergrund für kritische Noten (leicht rot)
  static const Color criticalBackground = Color(0xFFFFEBEE); // Colors.red[50]
  
  /// Rahmenfarbe (hell)
  static const Color border = Color(0xFFE0E0E0); // Colors.grey[300]
  
  /// Gibt die Farbe für eine Note zurück
  /// 
  /// Nur Noten 5 und 6 werden farbig hervorgehoben (rot),
  /// alle anderen Noten sind neutral (dunkelgrau).
  static Color getColor(int note) {
    switch (note) {
      case 5:
        return critical;
      case 6:
        return veryCritical;
      case 1:
      case 2:
      case 3:
      case 4:
        return neutral;
      default:
        return empty;
    }
  }
  
  /// Gibt die Hintergrundfarbe für eine Zelle basierend auf der Note zurück
  static Color getCellBackground(int? note) {
    if (note == null) return Colors.transparent;
    if (note >= 5) return criticalBackground;
    return Colors.transparent;
  }
}

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
