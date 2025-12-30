import 'package:flutter/foundation.dart';

/// Feature-Flags für granulare Lehrer-Berechtigungen
/// 
/// Admin kann pro Feature entscheiden, ob Lehrer es nutzen dürfen.
/// Flags werden in Firestore gespeichert: `/settings/features`
@immutable
class FeatureFlags {
  // CSV Import
  final bool canImportCSV;
  
  // Schüler
  final bool canCreateSchueler;
  final bool canEditSchueler;
  final bool canDeleteSchueler;
  
  // Fächer
  final bool canCreateFaecher;
  final bool canEditFaecher;
  final bool canDeleteFaecher;
  
  // Klassen
  final bool canCreateKlassen;
  final bool canEditKlassen;
  final bool canDeleteKlassen;
  
  // Leistungsnachweise
  final bool canCreateLeistungsnachweise;
  final bool canEditLeistungsnachweise;
  final bool canDeleteLeistungsnachweise;
  
  // Sonstige
  final bool canToggleFavorites;
  final bool canExportPDF;
  final bool canExportExcel;
  final bool canExportNOI;

  /// Default-Werte: Sichere Defaults für Lehrer
  const FeatureFlags({
    this.canImportCSV = false,            // Nur Admin
    this.canCreateSchueler = true,
    this.canEditSchueler = true,
    this.canDeleteSchueler = false,       // Nur Admin
    this.canCreateFaecher = false,        // Nur Admin
    this.canEditFaecher = false,          // Nur Admin
    this.canDeleteFaecher = false,        // Nur Admin
    this.canCreateKlassen = false,        // Nur Admin
    this.canEditKlassen = false,          // Nur Admin
    this.canDeleteKlassen = false,        // Nur Admin
    this.canCreateLeistungsnachweise = true,
    this.canEditLeistungsnachweise = true,
    this.canDeleteLeistungsnachweise = false, // Nur Admin
    this.canToggleFavorites = true,
    this.canExportPDF = true,
    this.canExportExcel = false,          // Nur Admin
    this.canExportNOI = true,
  });

  /// Alle Rechte (für Admin)
  const FeatureFlags.admin()
      : canImportCSV = true,
        canCreateSchueler = true,
        canEditSchueler = true,
        canDeleteSchueler = true,
        canCreateFaecher = true,
        canEditFaecher = true,
        canDeleteFaecher = true,
        canCreateKlassen = true,
        canEditKlassen = true,
        canDeleteKlassen = true,
        canCreateLeistungsnachweise = true,
        canEditLeistungsnachweise = true,
        canDeleteLeistungsnachweise = true,
        canToggleFavorites = true,
        canExportPDF = true,
        canExportExcel = true,
        canExportNOI = true;

  /// Aus Firestore-Daten erstellen
  factory FeatureFlags.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const FeatureFlags();
    
    return FeatureFlags(
      canImportCSV: data['canImportCSV'] as bool? ?? false,
      canCreateSchueler: data['canCreateSchueler'] as bool? ?? true,
      canEditSchueler: data['canEditSchueler'] as bool? ?? true,
      canDeleteSchueler: data['canDeleteSchueler'] as bool? ?? false,
      canCreateFaecher: data['canCreateFaecher'] as bool? ?? false,
      canEditFaecher: data['canEditFaecher'] as bool? ?? false,
      canDeleteFaecher: data['canDeleteFaecher'] as bool? ?? false,
      canCreateKlassen: data['canCreateKlassen'] as bool? ?? false,
      canEditKlassen: data['canEditKlassen'] as bool? ?? false,
      canDeleteKlassen: data['canDeleteKlassen'] as bool? ?? false,
      canCreateLeistungsnachweise: data['canCreateLeistungsnachweise'] as bool? ?? true,
      canEditLeistungsnachweise: data['canEditLeistungsnachweise'] as bool? ?? true,
      canDeleteLeistungsnachweise: data['canDeleteLeistungsnachweise'] as bool? ?? false,
      canToggleFavorites: data['canToggleFavorites'] as bool? ?? true,
      canExportPDF: data['canExportPDF'] as bool? ?? true,
      canExportExcel: data['canExportExcel'] as bool? ?? false,
      canExportNOI: data['canExportNOI'] as bool? ?? true,
    );
  }

  /// Zu Firestore-Daten konvertieren
  Map<String, dynamic> toFirestore() {
    return {
      'canImportCSV': canImportCSV,
      'canCreateSchueler': canCreateSchueler,
      'canEditSchueler': canEditSchueler,
      'canDeleteSchueler': canDeleteSchueler,
      'canCreateFaecher': canCreateFaecher,
      'canEditFaecher': canEditFaecher,
      'canDeleteFaecher': canDeleteFaecher,
      'canCreateKlassen': canCreateKlassen,
      'canEditKlassen': canEditKlassen,
      'canDeleteKlassen': canDeleteKlassen,
      'canCreateLeistungsnachweise': canCreateLeistungsnachweise,
      'canEditLeistungsnachweise': canEditLeistungsnachweise,
      'canDeleteLeistungsnachweise': canDeleteLeistungsnachweise,
      'canToggleFavorites': canToggleFavorites,
      'canExportPDF': canExportPDF,
      'canExportExcel': canExportExcel,
      'canExportNOI': canExportNOI,
    };
  }

  /// Copy with für einzelne Flag-Änderungen
  FeatureFlags copyWith({
    bool? canImportCSV,
    bool? canCreateSchueler,
    bool? canEditSchueler,
    bool? canDeleteSchueler,
    bool? canCreateFaecher,
    bool? canEditFaecher,
    bool? canDeleteFaecher,
    bool? canCreateKlassen,
    bool? canEditKlassen,
    bool? canDeleteKlassen,
    bool? canCreateLeistungsnachweise,
    bool? canEditLeistungsnachweise,
    bool? canDeleteLeistungsnachweise,
    bool? canToggleFavorites,
    bool? canExportPDF,
    bool? canExportExcel,
    bool? canExportNOI,
  }) {
    return FeatureFlags(
      canImportCSV: canImportCSV ?? this.canImportCSV,
      canCreateSchueler: canCreateSchueler ?? this.canCreateSchueler,
      canEditSchueler: canEditSchueler ?? this.canEditSchueler,
      canDeleteSchueler: canDeleteSchueler ?? this.canDeleteSchueler,
      canCreateFaecher: canCreateFaecher ?? this.canCreateFaecher,
      canEditFaecher: canEditFaecher ?? this.canEditFaecher,
      canDeleteFaecher: canDeleteFaecher ?? this.canDeleteFaecher,
      canCreateKlassen: canCreateKlassen ?? this.canCreateKlassen,
      canEditKlassen: canEditKlassen ?? this.canEditKlassen,
      canDeleteKlassen: canDeleteKlassen ?? this.canDeleteKlassen,
      canCreateLeistungsnachweise: canCreateLeistungsnachweise ?? this.canCreateLeistungsnachweise,
      canEditLeistungsnachweise: canEditLeistungsnachweise ?? this.canEditLeistungsnachweise,
      canDeleteLeistungsnachweise: canDeleteLeistungsnachweise ?? this.canDeleteLeistungsnachweise,
      canToggleFavorites: canToggleFavorites ?? this.canToggleFavorites,
      canExportPDF: canExportPDF ?? this.canExportPDF,
      canExportExcel: canExportExcel ?? this.canExportExcel,
      canExportNOI: canExportNOI ?? this.canExportNOI,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeatureFlags &&
        other.canImportCSV == canImportCSV &&
        other.canCreateSchueler == canCreateSchueler &&
        other.canEditSchueler == canEditSchueler &&
        other.canDeleteSchueler == canDeleteSchueler &&
        other.canCreateFaecher == canCreateFaecher &&
        other.canEditFaecher == canEditFaecher &&
        other.canDeleteFaecher == canDeleteFaecher &&
        other.canCreateKlassen == canCreateKlassen &&
        other.canEditKlassen == canEditKlassen &&
        other.canDeleteKlassen == canDeleteKlassen &&
        other.canCreateLeistungsnachweise == canCreateLeistungsnachweise &&
        other.canEditLeistungsnachweise == canEditLeistungsnachweise &&
        other.canDeleteLeistungsnachweise == canDeleteLeistungsnachweise &&
        other.canToggleFavorites == canToggleFavorites &&
        other.canExportPDF == canExportPDF &&
        other.canExportExcel == canExportExcel &&
        other.canExportNOI == canExportNOI;
  }

  @override
  int get hashCode => Object.hash(
        canImportCSV,
        canCreateSchueler,
        canEditSchueler,
        canDeleteSchueler,
        canCreateFaecher,
        canEditFaecher,
        canDeleteFaecher,
        canCreateKlassen,
        canEditKlassen,
        canDeleteKlassen,
        canCreateLeistungsnachweise,
        canEditLeistungsnachweise,
        canDeleteLeistungsnachweise,
        canToggleFavorites,
        canExportPDF,
        canExportExcel,
        canExportNOI,
      );
}

/// Einzelnes Feature-Flag mit Metadaten für UI
class FeatureFlagInfo {
  final String key;
  final String label;
  final String description;
  final String category;
  final bool defaultValue;

  const FeatureFlagInfo({
    required this.key,
    required this.label,
    required this.description,
    required this.category,
    required this.defaultValue,
  });

  /// Alle verfügbaren Feature-Flags mit UI-Infos
  static const List<FeatureFlagInfo> all = [
    // Import
    FeatureFlagInfo(
      key: 'canImportCSV',
      label: 'CSV Import',
      description: 'Schüler aus ASV-CSV importieren',
      category: 'Import/Export',
      defaultValue: false,
    ),
    // Schüler
    FeatureFlagInfo(
      key: 'canCreateSchueler',
      label: 'Schüler anlegen',
      description: 'Neue Schüler manuell erstellen',
      category: 'Schüler',
      defaultValue: true,
    ),
    FeatureFlagInfo(
      key: 'canEditSchueler',
      label: 'Schüler bearbeiten',
      description: 'Schülerdaten ändern',
      category: 'Schüler',
      defaultValue: true,
    ),
    FeatureFlagInfo(
      key: 'canDeleteSchueler',
      label: 'Schüler löschen',
      description: 'Schüler aus System entfernen',
      category: 'Schüler',
      defaultValue: false,
    ),
    // Fächer
    FeatureFlagInfo(
      key: 'canCreateFaecher',
      label: 'Fächer anlegen',
      description: 'Neue Unterrichtsfächer erstellen',
      category: 'Fächer',
      defaultValue: false,
    ),
    FeatureFlagInfo(
      key: 'canEditFaecher',
      label: 'Fächer bearbeiten',
      description: 'Fächerdaten ändern',
      category: 'Fächer',
      defaultValue: false,
    ),
    FeatureFlagInfo(
      key: 'canDeleteFaecher',
      label: 'Fächer löschen',
      description: 'Fächer aus System entfernen',
      category: 'Fächer',
      defaultValue: false,
    ),
    // Klassen
    FeatureFlagInfo(
      key: 'canCreateKlassen',
      label: 'Klassen anlegen',
      description: 'Neue Schulklassen erstellen',
      category: 'Klassen',
      defaultValue: false,
    ),
    FeatureFlagInfo(
      key: 'canEditKlassen',
      label: 'Klassen bearbeiten',
      description: 'Klassendaten ändern',
      category: 'Klassen',
      defaultValue: false,
    ),
    FeatureFlagInfo(
      key: 'canDeleteKlassen',
      label: 'Klassen löschen',
      description: 'Klassen aus System entfernen',
      category: 'Klassen',
      defaultValue: false,
    ),
    // Leistungsnachweise
    FeatureFlagInfo(
      key: 'canCreateLeistungsnachweise',
      label: 'LN anlegen',
      description: 'Neue Leistungsnachweise erstellen',
      category: 'Leistungsnachweise',
      defaultValue: true,
    ),
    FeatureFlagInfo(
      key: 'canEditLeistungsnachweise',
      label: 'LN bearbeiten',
      description: 'Leistungsnachweise ändern',
      category: 'Leistungsnachweise',
      defaultValue: true,
    ),
    FeatureFlagInfo(
      key: 'canDeleteLeistungsnachweise',
      label: 'LN löschen',
      description: 'Leistungsnachweise entfernen',
      category: 'Leistungsnachweise',
      defaultValue: false,
    ),
    // Sonstige
    FeatureFlagInfo(
      key: 'canToggleFavorites',
      label: 'Favoriten verwalten',
      description: 'Klassen als Favoriten markieren',
      category: 'Sonstige',
      defaultValue: true,
    ),
    FeatureFlagInfo(
      key: 'canExportPDF',
      label: 'PDF Export',
      description: 'Daten als PDF exportieren',
      category: 'Import/Export',
      defaultValue: true,
    ),
    FeatureFlagInfo(
      key: 'canExportExcel',
      label: 'Excel Export',
      description: 'Daten als Excel exportieren',
      category: 'Import/Export',
      defaultValue: false,
    ),
    FeatureFlagInfo(
      key: 'canExportNOI',
      label: 'NOI Export',
      description: 'Daten im NOI-Format exportieren',
      category: 'Import/Export',
      defaultValue: true,
    ),
  ];

  /// Gruppiert nach Kategorie
  static Map<String, List<FeatureFlagInfo>> get byCategory {
    final result = <String, List<FeatureFlagInfo>>{};
    for (final flag in all) {
      result.putIfAbsent(flag.category, () => []).add(flag);
    }
    return result;
  }
}
