import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// RBS Styleguide 1.2 - Official Design System
/// Referat für Bildung und Sport, Landeshauptstadt München
///
/// Verbindliche Farben, Typografie und Layout-Regeln gemäß Styleguide

class RBSColors {
  // PRIMARY COLOR - Dynamic Red (verpflichtend)
  static const Color dynamicRed = Color(0xFFFF5E35); // RGB 255/94/53
  
  // SECONDARY COLORS
  static const Color growingElder = Color(0xFF9BB537); // Grünton
  static const Color courtGreen = Color(0xFF00AB84);   // Türkis
  
  // NEUTRAL COLORS
  static const Color white = Color(0xFFFFFFFF);
  static const Color paper = Color(0xFFFAFAFA);        // Sehr helles Grau
  static const Color offwhite = Color(0xFFF5F5F5);     // Offwhite für Hintergründe
  
  // TEXT COLORS (automatisch nach Kontrast)
  static const Color textOnLight = Color(0xFF212121);  // Schwarz auf hellem Grund
  static const Color textOnDark = Color(0xFFFFFFFF);   // Weiß auf dunklem Grund
  static const Color textOnRed = Color(0xFFFFFFFF);    // Weiß auf Dynamic Red
  
  // ABLEITUNGEN (nur dezent als Hintergründe auf Content-Ebene)
  static const Color elderLight = Color(0xFFE8F0D0);   // Heller Elder-Ton
  static const Color greenLight = Color(0xFFCCEFE7);   // Heller Green-Ton
  static const Color redLight = Color(0xFFFFE5DF);     // Heller Red-Ton
  
  // FUNCTIONAL COLORS
  static const Color success = courtGreen;
  static const Color warning = Color(0xFFFFA726);
  static const Color error = dynamicRed;
  static const Color info = Color(0xFF29B6F6);
}

class RBSTypography {
  // HEADLINE FONT - Roboto Condensed Bold
  static const String headlineFont = 'Roboto Condensed';
  
  // BODY FONT - Open Sans
  static const String bodyFont = 'Open Sans';
  
  // FONT WEIGHTS
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight regular = FontWeight.w400;
  
  // TEXT STYLES - Roboto Condensed Bold für Überschriften
  static const TextStyle h1 = TextStyle(
    fontFamily: headlineFont,
    fontSize: 32,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: 0, // Laufweite normal
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: headlineFont,
    fontSize: 24,
    fontWeight: bold,
    height: 1.3,
    letterSpacing: 0,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: headlineFont,
    fontSize: 20,
    fontWeight: bold,
    height: 1.4,
    letterSpacing: 0,
  );
  
  static const TextStyle h4 = TextStyle(
    fontFamily: headlineFont,
    fontSize: 18,
    fontWeight: bold,
    height: 1.4,
    letterSpacing: 0,
  );
  
  // BODY TEXT - Open Sans
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0,
  );
  
  // BUTTON TEXT - Roboto Condensed Bold
  static const TextStyle button = TextStyle(
    fontFamily: headlineFont,
    fontSize: 14,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: 0,
  );
  
  // TAG TEXT - Roboto Condensed Bold (Outline)
  static const TextStyle tag = TextStyle(
    fontFamily: headlineFont,
    fontSize: 12,
    fontWeight: bold,
    height: 1.0,
    letterSpacing: 0,
  );
}

class RBSSpacing {
  // GRID-BASIERTES SPACING (8dp-Basis)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // CARD PADDING (großzügig gemäß Styleguide)
  static const EdgeInsets cardPadding = EdgeInsets.all(24.0);
  
  // SECTION SPACING
  static const double sectionGap = 32.0;
}

class RBSBorderRadius {
  // LEICHTE RUNDUNGEN (gemäß Styleguide)
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;
}

class RBSTheme {
  /// Erstellt das vollständige RBS Theme für die App
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      
      // COLOR SCHEME - Dynamic Red als Primary
      colorScheme: ColorScheme.light(
        primary: RBSColors.dynamicRed,
        onPrimary: RBSColors.textOnRed,
        secondary: RBSColors.growingElder,
        onSecondary: RBSColors.textOnDark,
        tertiary: RBSColors.courtGreen,
        onTertiary: RBSColors.textOnDark,
        surface: RBSColors.white,
        onSurface: RBSColors.textOnLight,
        error: RBSColors.error,
        onError: RBSColors.textOnDark,
      ),
      
      // TYPOGRAPHY - Roboto Condensed + Open Sans via Google Fonts
      textTheme: GoogleFonts.openSansTextTheme().copyWith(
        displayLarge: GoogleFonts.robotoCondensed(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: RBSColors.textOnLight,
        ),
        displayMedium: GoogleFonts.robotoCondensed(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: RBSColors.textOnLight,
        ),
        displaySmall: GoogleFonts.robotoCondensed(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: RBSColors.textOnLight,
        ),
        headlineMedium: GoogleFonts.robotoCondensed(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: RBSColors.textOnLight,
        ),
        bodyLarge: GoogleFonts.openSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: RBSColors.textOnLight,
        ),
        bodyMedium: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: RBSColors.textOnLight,
        ),
        bodySmall: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: RBSColors.textOnLight,
        ),
        labelLarge: GoogleFonts.robotoCondensed(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: RBSColors.textOnLight,
        ),
      ),
      
      // APP BAR - Dynamic Red (auf Cover-Ebene)
      appBarTheme: AppBarTheme(
        backgroundColor: RBSColors.dynamicRed,
        foregroundColor: RBSColors.textOnRed,
        elevation: 0,
        centerTitle: false, // Linksbündig gemäß Styleguide
        titleTextStyle: GoogleFonts.robotoCondensed(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: RBSColors.textOnRed,
        ),
      ),
      
      // CARD - Weiche Schatten, viel Weißraum
      cardTheme: CardThemeData(
        color: RBSColors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: RBSSpacing.md,
          vertical: RBSSpacing.sm,
        ),
      ),
      
      // BUTTON - Dynamic Red, Roboto Condensed Bold
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RBSColors.dynamicRed,
          foregroundColor: RBSColors.textOnRed,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(
            horizontal: RBSSpacing.lg,
            vertical: RBSSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RBSBorderRadius.small),
          ),
          textStyle: RBSTypography.button,
        ),
      ),
      
      // OUTLINED BUTTON - Für Tags und sekundäre Aktionen
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RBSColors.dynamicRed,
          side: const BorderSide(color: RBSColors.dynamicRed, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: RBSSpacing.md,
            vertical: RBSSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RBSBorderRadius.small),
          ),
          textStyle: RBSTypography.tag,
        ),
      ),
      
      // INPUT FIELDS - Klar, weiß, Outline bei Fokus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RBSColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RBSSpacing.md,
          vertical: RBSSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RBSBorderRadius.small),
          borderSide: BorderSide(color: RBSColors.textOnLight.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RBSBorderRadius.small),
          borderSide: BorderSide(color: RBSColors.textOnLight.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RBSBorderRadius.small),
          borderSide: const BorderSide(color: RBSColors.dynamicRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RBSBorderRadius.small),
          borderSide: const BorderSide(color: RBSColors.error, width: 2),
        ),
        labelStyle: RBSTypography.bodyMedium.copyWith(
          color: RBSColors.textOnLight.withValues(alpha: 0.6),
        ),
        hintStyle: RBSTypography.bodyMedium.copyWith(
          color: RBSColors.textOnLight.withValues(alpha: 0.4),
        ),
      ),
      
      // SCAFFOLD - Offwhite Hintergrund für Content-Ebene
      scaffoldBackgroundColor: RBSColors.offwhite,
      
      // DIVIDER - Dezent
      dividerTheme: DividerThemeData(
        color: RBSColors.textOnLight.withValues(alpha: 0.1),
        thickness: 1,
        space: RBSSpacing.md,
      ),
      
      // CHIP - Ähnlich wie Tag (Outline)
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: RBSColors.dynamicRed.withValues(alpha: 0.1),
        side: const BorderSide(color: RBSColors.dynamicRed, width: 2),
        labelStyle: RBSTypography.tag,
        padding: const EdgeInsets.symmetric(
          horizontal: RBSSpacing.sm,
          vertical: RBSSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RBSBorderRadius.small),
        ),
      ),
    );
  }
}
