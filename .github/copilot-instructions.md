# Notentool Web - Copilot Instructions

## Project Overview
**notentool_web** is a Flutter web application for managing student grades/marks (Notenverwaltung).

## Tech Stack
- **Framework**: Flutter 3.x (Web)
- **Language**: Dart 3.x
- **State Management**: Riverpod
- **Backend**: Firebase (Firestore, Auth)
- **Routing**: go_router
- **UI**: Material Design 3

## Project Structure
```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models (Grade, Student, Subject)
├── providers/                # Riverpod providers
├── screens/                  # UI screens
├── services/                 # Business logic (GradeService, AuthService)
└── widgets/                  # Reusable components
```

## Development Guidelines
- Use Riverpod for all state management
- Follow Flutter best practices for web (responsive design)
- Keep business logic in services, not in UI
- Use Firebase Firestore for data persistence
- Implement proper error handling for web context
- Use go_router for navigation

## Common Commands
- `flutter run -d chrome` - Run in Chrome
- `flutter build web` - Build for production
- `flutter test` - Run tests
- `flutter pub get` - Install dependencies

## Firebase Setup
- Firebase project must be configured with web app
- Firestore rules must allow authenticated access
- Auth providers: Email/Password (minimum)
