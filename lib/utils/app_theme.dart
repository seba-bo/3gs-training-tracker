import 'package:flutter/material.dart';

class AppTheme {
  // Modern Color Palette
  static const Color primaryDark = Color(0xFF0A0E27);
  static const Color secondaryDark = Color(0xFF1A1F3A);
  static const Color cardBg = Color(0xFF252B48);
  static const Color accentBlue = Color(0xFF5BA3F5);      // Heller für bessere Lesbarkeit
  static const Color accentGreen = Color(0xFF3DDC84);     // Heller für bessere Lesbarkeit
  static const Color accentOrange = Color(0xFFFF9F43);    // Heller für bessere Lesbarkeit
  static const Color accentRed = Color(0xFFFF6B6B);       // Heller für bessere Lesbarkeit
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8C4);
  static const Color divider = Color(0xFF3A4058);
  
  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, secondaryDark],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF252B48), Color(0xFF1F2540)],
  );
  
  // Shadows
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  static final List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ];
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  
  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
  );
  
  // Button Styles
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: accentGreen,
    foregroundColor: Color(0xFF000000), // Schwarz auf grün für maximalen Kontrast
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    shadowColor: Colors.black.withOpacity(0.3),
    textStyle: const TextStyle(
      color: Color(0xFF000000),
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );
  
  static final ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: accentBlue,
    foregroundColor: Color(0xFF000000), // Schwarz auf blau
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    textStyle: const TextStyle(
      color: Color(0xFF000000),
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );
  
  static final ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: accentRed,
    foregroundColor: Colors.white, // Weiß auf rot
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    textStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );
  
  static final ButtonStyle warningButton = ElevatedButton.styleFrom(
    backgroundColor: accentOrange,
    foregroundColor: Color(0xFF000000), // Schwarz auf orange
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    textStyle: const TextStyle(
      color: Color(0xFF000000),
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );
  
  static final ButtonStyle ghostButton = ElevatedButton.styleFrom(
    backgroundColor: cardBg,
    foregroundColor: Colors.white, // Weiß auf dunkel
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    textStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );
  
  // Input Decoration
  static InputDecoration inputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textSecondary),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Color(0xFF3A4366), // Heller als cardBg für bessere Sichtbarkeit
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: accentBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
    );
  }
  
  // Card Decoration
  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      gradient: color == null ? cardGradient : null,
      color: color,
      borderRadius: BorderRadius.circular(radiusLarge),
      boxShadow: cardShadow,
      border: Border.all(
        color: Colors.white.withOpacity(0.05),
        width: 1,
      ),
    );
  }
  
  // Animated Container
  static Widget buildGlassCard({
    required Widget child,
    EdgeInsets? padding,
    Color? color,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(spaceL),
      decoration: cardDecoration(color: color),
      child: child,
    );
  }
  
  // Badge
  static Widget buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(radiusSmall),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  // Icon Button
  static Widget buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 20,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: size),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
  
  // Avatar
  static Widget buildAvatar({
    required IconData icon,
    required Color color,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
  
  // Stat Card
  static Widget buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.heading2.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}