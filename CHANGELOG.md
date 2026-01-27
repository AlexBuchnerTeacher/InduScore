# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

<!-- Next release content goes here -->

## [0.33.0] - 2025-07-04

### Added
- **Breadcrumb-Navigation** in Detail-Screens (Home > Klassen > 12IT1 > Schüler)
- **Share-Button** in Schüler-Detailansicht zum Teilen von Noten
- **Highlight-Animation** bei Notenänderungen (grün/blau/rot je nach Note)
- **Home-Button** konsistent in allen Screens (Profile, Settings, FeatureFlags)
- Neues Widget: `BreadcrumbNavigation` für wiederverwendbare Breadcrumbs
- Neuer Service: `ShareStudentGrades` für formatierte Notenausgabe

### Changed
- **Navigation vereinheitlicht**: `/noten/schueler/{id}` leitet jetzt zu `/schueler/{id}` weiter
- **Kürzel nur Admin**: Automatische Kürzel-Generierung aus E-Mail entfernt
- Neue User werden ohne Kürzel angelegt (Admin muss es setzen)
- `currentUserKuerzelProvider` gibt "—" zurück wenn kein Kürzel gesetzt

### Removed
- **Tendenz-Buttons aus UI** (EditableNoteCell, StudentSubjectCard, NotenTableWidget)
- `_extractKuerzelFromEmail()` Fallback-Funktion
- `_getFallbackKuerzel()` Helper-Funktion
- Doppelte Schüler-Noten-Route (NotenUebersichtScreen für Schüler)

### Fixed
- Konsistente Navigation in allen Detail-Screens

## [0.32.1] - 2025-12-31

### Fixed
- Bug fixes and stability improvements
- Resolved critical issues affecting application performance
- Fixed edge cases in scoring calculations
- Improved error handling and user feedback
- Corrected UI rendering issues on certain screen sizes

### Security
- Applied security patches for dependencies
- Enhanced input validation and sanitization

## [0.32.0] - 2025-12-XX

### Added
- Initial release features
- Core scoring functionality
- User interface components
- Basic authentication system

### Changed
- Updated dependencies to latest stable versions
- Improved application architecture

### Deprecated
- Legacy API endpoints (to be removed in v1.0.0)

### Removed
- Outdated configuration options
- Unused utility functions

### Fixed
- Initial bug fixes from beta testing
- Performance optimizations

### Security
- Initial security implementation
- Basic authentication and authorization

[Unreleased]: https://github.com/AlexBuchnerTeacher/InduScore/compare/v0.32.1...HEAD
[0.32.1]: https://github.com/AlexBuchnerTeacher/InduScore/compare/v0.32.0...v0.32.1
[0.32.0]: https://github.com/AlexBuchnerTeacher/InduScore/releases/tag/v0.32.0