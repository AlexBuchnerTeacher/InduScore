import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/core/theme/rbs_theme.dart';

void main() {
  // Binding für Google Fonts initialisieren
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RBSColors', () {
    test('dynamicRed hat korrekte Farbe', () {
      expect(RBSColors.dynamicRed, const Color(0xFFFF5E35));
    });

    test('secondary colors sind definiert', () {
      expect(RBSColors.growingElder, isA<Color>());
      expect(RBSColors.courtGreen, isA<Color>());
    });

    test('fromHex parst 6-stelligen Hex-Code', () {
      final color = RBSColors.fromHex('#FF5E35');
      expect(color, isNotNull);
      expect(color!.red, 255);
      expect(color.green, 94);
      expect(color.blue, 53);
    });

    test('fromHex parst ohne Hash-Zeichen', () {
      final color = RBSColors.fromHex('00AB84');
      expect(color, isNotNull);
    });

    test('fromHex parst 8-stelligen Hex-Code', () {
      final color = RBSColors.fromHex('FFFF5E35');
      expect(color, isNotNull);
    });

    test('fromHex liefert null bei ungültigem Input', () {
      expect(RBSColors.fromHex(null), isNull);
      expect(RBSColors.fromHex(''), isNull);
      expect(RBSColors.fromHex('invalid'), isNull);
      expect(RBSColors.fromHex('XYZ'), isNull);
    });

    test('toHex konvertiert Color zu Hex-String', () {
      final hex = RBSColors.toHex(const Color(0xFFFF5E35));
      expect(hex.toUpperCase(), '#FF5E35');
    });

    test('subjectColors hat 10 Farben', () {
      expect(RBSColors.subjectColors.length, 10);
      for (final color in RBSColors.subjectColors) {
        expect(color, isA<Color>());
      }
    });

    test('functional colors sind definiert', () {
      expect(RBSColors.success, RBSColors.courtGreen);
      expect(RBSColors.error, RBSColors.dynamicRed);
      expect(RBSColors.warning, isA<Color>());
      expect(RBSColors.info, isA<Color>());
    });
  });

  group('RBSTypography', () {
    test('headline font ist Roboto Condensed', () {
      expect(RBSTypography.headlineFont, 'Roboto Condensed');
    });

    test('body font ist Open Sans', () {
      expect(RBSTypography.bodyFont, 'Open Sans');
    });

    test('h1 TextStyle ist definiert', () {
      expect(RBSTypography.h1, isA<TextStyle>());
      expect(RBSTypography.h1.fontSize, greaterThan(20));
    });

    test('bodyMedium TextStyle ist definiert', () {
      expect(RBSTypography.bodyMedium, isA<TextStyle>());
    });

    test('alle headline styles sind definiert', () {
      expect(RBSTypography.h1, isA<TextStyle>());
      expect(RBSTypography.h2, isA<TextStyle>());
      expect(RBSTypography.h3, isA<TextStyle>());
      expect(RBSTypography.h4, isA<TextStyle>());
    });
  });

  group('RBSSpacing', () {
    test('spacing values sind definiert', () {
      expect(RBSSpacing.xs, 4.0);
      expect(RBSSpacing.sm, 8.0);
      expect(RBSSpacing.md, 16.0);
      expect(RBSSpacing.lg, 24.0);
      expect(RBSSpacing.xl, 32.0);
    });
  });

  // RBSTheme Tests auskommentiert - benötigen Google Fonts HTTP-Zugriff im Test
  // Die Tests sind in Widget-Tests mit pumpWidget besser aufgehoben
}
