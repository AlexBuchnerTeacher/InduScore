import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/features/noten/noten_layout_constants.dart';

void main() {
  group('NotenColors', () {
    test('critical grades (5, 6) return red colors', () {
      expect(NotenColors.getColor(5), equals(NotenColors.critical));
      expect(NotenColors.getColor(6), equals(NotenColors.veryCritical));
    });

    test('good grades (1-4) return neutral color', () {
      expect(NotenColors.getColor(1), equals(NotenColors.neutral));
      expect(NotenColors.getColor(2), equals(NotenColors.neutral));
      expect(NotenColors.getColor(3), equals(NotenColors.neutral));
      expect(NotenColors.getColor(4), equals(NotenColors.neutral));
    });

    test('invalid grades return empty color', () {
      expect(NotenColors.getColor(0), equals(NotenColors.empty));
      expect(NotenColors.getColor(7), equals(NotenColors.empty));
      expect(NotenColors.getColor(-1), equals(NotenColors.empty));
    });

    test('getCellBackground returns transparent for good grades', () {
      expect(NotenColors.getCellBackground(1), equals(Colors.transparent));
      expect(NotenColors.getCellBackground(2), equals(Colors.transparent));
      expect(NotenColors.getCellBackground(3), equals(Colors.transparent));
      expect(NotenColors.getCellBackground(4), equals(Colors.transparent));
    });

    test('getCellBackground returns critical background for grades 5 and 6', () {
      expect(NotenColors.getCellBackground(5), equals(NotenColors.criticalBackground));
      expect(NotenColors.getCellBackground(6), equals(NotenColors.criticalBackground));
    });

    test('getCellBackground returns transparent for null', () {
      expect(NotenColors.getCellBackground(null), equals(Colors.transparent));
    });

    test('color constants are correct hex values', () {
      // Kritische Farben = Rot-Töne
      expect(NotenColors.critical, equals(const Color(0xFFD32F2F)));
      expect(NotenColors.veryCritical, equals(const Color(0xFFB71C1C)));
      
      // Neutrale Farbe = Dunkelgrau
      expect(NotenColors.neutral, equals(const Color(0xFF424242)));
      
      // Border = Hellgrau
      expect(NotenColors.border, equals(const Color(0xFFE0E0E0)));
    });
  });

  group('NotenSpacing', () {
    test('spacing values are correct', () {
      expect(NotenSpacing.xs, equals(4.0));
      expect(NotenSpacing.sm, equals(6.0));
      expect(NotenSpacing.md, equals(8.0));
      expect(NotenSpacing.lg, equals(12.0));
    });
  });

  group('NotenTableDimensions', () {
    test('dimension values are correct', () {
      expect(NotenTableDimensions.rowHeightMin, equals(40.0));
      expect(NotenTableDimensions.rowHeightMax, equals(40.0));
      expect(NotenTableDimensions.headerHeight, equals(48.0));
      expect(NotenTableDimensions.columnSpacing, equals(6.0));
      expect(NotenTableDimensions.noteDropdownWidth, equals(42.0));
    });
  });

  group('NotenFontSizes', () {
    test('font sizes are correct', () {
      expect(NotenFontSizes.studentName, equals(13.0));
      expect(NotenFontSizes.noteValue, equals(13.0));
      expect(NotenFontSizes.header, equals(11.0));
      expect(NotenFontSizes.kuerzel, equals(7.0));
      expect(NotenFontSizes.average, equals(12.0));
    });
  });
}
