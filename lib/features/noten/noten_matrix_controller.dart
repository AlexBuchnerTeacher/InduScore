import 'package:flutter/material.dart';

/// Controller für NotenMatrixView
/// 
/// Verwaltet:
/// - TextField Controller für Noten-Eingabe
/// - Focus Nodes
/// - Scroll Controller
/// 
/// Keine Businesslogik, nur UI-State Management
class NotenMatrixController extends ChangeNotifier {
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final ScrollController horizontalScrollController = ScrollController();
  final ScrollController verticalScrollController = ScrollController();

  /// Holt oder erstellt TextEditingController für eine Note
  TextEditingController getTextController(String key) {
    if (!_textControllers.containsKey(key)) {
      _textControllers[key] = TextEditingController();
    }
    return _textControllers[key]!;
  }

  /// Holt oder erstellt FocusNode für eine Note
  FocusNode getFocusNode(String key) {
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
    }
    return _focusNodes[key]!;
  }

  /// Setzt Fokus auf eine spezifische Zelle
  void focusCell(String key) {
    final node = getFocusNode(key);
    node.requestFocus();
  }

  /// Löscht alle Controller und Nodes
  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    horizontalScrollController.dispose();
    verticalScrollController.dispose();
    super.dispose();
  }

  /// Entfernt Controller/Node für eine Zelle (z.B. wenn Schüler gelöscht wird)
  void removeCell(String key) {
    _textControllers[key]?.dispose();
    _textControllers.remove(key);
    _focusNodes[key]?.dispose();
    _focusNodes.remove(key);
  }

  /// Löscht alle Controller/Nodes (z.B. bei Filter-Änderung)
  void clearAll() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _textControllers.clear();
    _focusNodes.clear();
    notifyListeners();
  }
}
