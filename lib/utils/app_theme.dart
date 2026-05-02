import 'package:flutter/material.dart';

class AppTheme {
  // ══════════════════════════════════════════════════════════════════
  //  ROLE COLOURS — refined, high-contrast palette
  // ══════════════════════════════════════════════════════════════════

  // ── Admin  (Indigo-Blue) ───────────────────────────────────────────
  static const Color adminPrimary  = Color(0xFF4F6CF7); // vibrant indigo
  static const Color adminDark     = Color(0xFF2D4EE8); // deeper indigo
  static const Color adminLight    = Color(0xFFEEF2FF); // soft indigo tint

  // ── Tenant  (Violet-Purple) ────────────────────────────────────────
  static const Color tenantPrimary = Color(0xFF8B5CF6); // violet
  static const Color tenantDark    = Color(0xFF6D28D9); // deep violet
  static const Color tenantLight   = Color(0xFFF5F0FF); // lavender tint

  // ── Provider  (Amber-Orange) ───────────────────────────────────────
  static const Color providerPrimary = Color(0xFFF59E0B); // amber
  static const Color providerDark    = Color(0xFFD97706); // deep amber
  static const Color providerLight   = Color(0xFFFFFBEB); // warm yellow tint

  // ── User  (Emerald-Green) ─────────────────────────────────────────
  static const Color userPrimary = Color(0xFF10B981); // emerald
  static const Color userDark    = Color(0xFF059669); // deep emerald
  static const Color userLight   = Color(0xFFECFDF5); // mint tint

  // ══════════════════════════════════════════════════════════════════
  //  LIGHT MODE NEUTRALS
  // ══════════════════════════════════════════════════════════════════
  static const Color background    = Color(0xFFF7F8FC); // cool off-white
  static const Color surface       = Color(0xFFF7F8FC);
  static const Color cardBg        = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color textHint      = Color(0xFF94A3B8); // slate-400
  static const Color dividerColor  = Color(0xFFE2E8F0); // slate-200

  // ══════════════════════════════════════════════════════════════════
  //  DARK MODE NEUTRALS  — rich navy, not flat black
  // ══════════════════════════════════════════════════════════════════
  static const Color darkBackground   = Color(0xFF0B0F19); // deep navy
  static const Color darkSurface      = Color(0xFF111827); // gray-900
  static const Color darkCard         = Color(0xFF1A2236); // navy card
  static const Color darkInput        = Color(0xFF1E2A40); // input bg
  static const Color darkTextPrimary  = Color(0xFFF1F5F9); // slate-100
  static const Color darkTextSecondary= Color(0xFF94A3B8); // slate-400
  static const Color darkTextHint     = Color(0xFF475569); // slate-600
  static const Color darkDivider      = Color(0xFF1E293B); // slate-800

  // ══════════════════════════════════════════════════════════════════
  //  STATUS COLOURS — consistent semantic palette
  // ══════════════════════════════════════════════════════════════════
  static const Color statusRequested  = Color(0xFF64748B); // neutral slate
  static const Color statusAssigned   = Color(0xFF3B82F6); // blue-500
  static const Color statusAccepted   = Color(0xFF6366F1); // indigo-500
  static const Color statusInProgress = Color(0xFFF59E0B); // amber-500
  static const Color statusCompleted  = Color(0xFF10B981); // emerald-500
  static const Color statusResolved   = Color(0xFF059669); // emerald-600
  static const Color statusPending    = Color(0xFFF59E0B); // amber-500
  static const Color statusCancelled  = Color(0xFFEF4444); // red-500
  static const Color statusInactive   = Color(0xFFEF4444); // red-500
  static const Color statusActive     = Color(0xFF10B981); // emerald-500

  // ══════════════════════════════════════════════════════════════════
  //  ROLE HELPERS
  // ══════════════════════════════════════════════════════════════════

  static Color primaryForRole(String role) {
    switch (role.toLowerCase().trim()) {
      case 'tenant':                    return tenantPrimary;
      case 'provider':
      case 'service_provider':          return providerPrimary;
      case 'user':
      case 'customer':                  return userPrimary;
      case 'admin':
      default:                          return adminPrimary;
    }
  }

  static Color darkForRole(String role) {
    switch (role.toLowerCase().trim()) {
      case 'tenant':                    return tenantDark;
      case 'provider':
      case 'service_provider':          return providerDark;
      case 'user':
      case 'customer':                  return userDark;
      case 'admin':
      default:                          return adminDark;
    }
  }

  static Color lightForRole(String role) {
    switch (role.toLowerCase().trim()) {
      case 'tenant':                    return tenantLight;
      case 'provider':
      case 'service_provider':          return providerLight;
      case 'user':
      case 'customer':                  return userLight;
      case 'admin':
      default:                          return adminLight;
    }
  }

  static LinearGradient gradientForRole(String role) {
    switch (role.toLowerCase().trim()) {
      case 'tenant':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
        );
      case 'provider':
      case 'service_provider':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
        );
      case 'user':
      case 'customer':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF10B981)],
        );
      case 'admin':
      default:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF2D4EE8), Color(0xFF4F6CF7)],
        );
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  STATUS → COLOUR LOOKUPS
  // ══════════════════════════════════════════════════════════════════

  static Color getStatusColor(String status) {
    final normalized = status.toLowerCase().trim();
    if (normalized.startsWith('cancelled by ')) return statusCancelled;

    switch (normalized) {
      case 'requested':              return statusRequested;
      case 'new request':            return statusRequested;
      case 'assigned':               return statusAssigned;
      case 'new job assigned':       return statusAssigned;
      case 'finding a provider...':  return statusAssigned;
      case 'accepted':               return statusAccepted;
      case 'provider assigned':      return statusAccepted;
      case 'rejected -> reassign required':
                                   return statusInactive;
      case 'in progress':
      case 'in_progress':            return statusInProgress;
      case 'pending':                return statusPending;
      case 'completed':              return statusCompleted;
      case 'cancelled':
      case 'canceled':               return statusCancelled;
      case 'resolved':
      case 'no_show':                return statusResolved;
      case 'inactive':               return statusInactive;
      case 'active':                 return statusActive;
      case 'out of stock':           return statusInactive;
      case 'available':              return statusCompleted;
      case 'maintenance':            return statusInProgress;
      default:                       return textSecondary;
    }
  }

  /// Pastel background for status badges — works in both light + dark
  static Color getStatusBgColor(String status) {
    final normalized = status.toLowerCase().trim();
    if (normalized.startsWith('cancelled by ')) return const Color(0xFFFEF2F2);

    switch (normalized) {
      case 'requested':              return const Color(0xFFF1F5F9);
      case 'new request':            return const Color(0xFFF1F5F9);
      case 'assigned':               return const Color(0xFFEFF6FF);
      case 'new job assigned':       return const Color(0xFFEFF6FF);
      case 'finding a provider...':  return const Color(0xFFEFF6FF);
      case 'accepted':               return const Color(0xFFEEF2FF);
      case 'provider assigned':      return const Color(0xFFEEF2FF);
      case 'rejected -> reassign required':
                                   return const Color(0xFFFEF2F2);
      case 'in progress':
      case 'in_progress':            return const Color(0xFFFFFBEB);
      case 'pending':                return const Color(0xFFFFFBEB);
      case 'completed':              return const Color(0xFFECFDF5);
      case 'cancelled':
      case 'canceled':               return const Color(0xFFFEF2F2);
      case 'resolved':
      case 'no_show':                return const Color(0xFFECFDF5);
      case 'inactive':               return const Color(0xFFFEF2F2);
      case 'active':                 return const Color(0xFFECFDF5);
      case 'out of stock':           return const Color(0xFFFEF2F2);
      case 'available':              return const Color(0xFFECFDF5);
      case 'maintenance':            return const Color(0xFFFFFBEB);
      default:                       return surface;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ══════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tenantPrimary,
        primary: tenantPrimary,
        surface: surface,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 18,
            fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.zero,
      ),
      dividerColor: dividerColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: tenantPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: statusInactive)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: statusInactive, width: 1.5)),
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
            color: textSecondary),
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
            color: textHint),
        errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
            color: statusInactive),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: tenantPrimary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 10,
            fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 10),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 18,
            fontWeight: FontWeight.w700, color: textPrimary),
        contentTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
            color: textSecondary),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: 'Poppins', fontSize: 32,
            fontWeight: FontWeight.w800, color: textPrimary),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontSize: 26,
            fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium:TextStyle(fontFamily: 'Poppins', fontSize: 22,
            fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge:    TextStyle(fontFamily: 'Poppins', fontSize: 18,
            fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium:   TextStyle(fontFamily: 'Poppins', fontSize: 16,
            fontWeight: FontWeight.w500, color: textPrimary),
        titleSmall:    TextStyle(fontFamily: 'Poppins', fontSize: 14,
            fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge:     TextStyle(fontFamily: 'Poppins', fontSize: 15,
            color: textPrimary),
        bodyMedium:    TextStyle(fontFamily: 'Poppins', fontSize: 13,
            color: textSecondary),
        bodySmall:     TextStyle(fontFamily: 'Poppins', fontSize: 12,
            color: textSecondary),
        labelLarge:    TextStyle(fontFamily: 'Poppins', fontSize: 13,
            fontWeight: FontWeight.w600, color: textPrimary),
        labelSmall:    TextStyle(fontFamily: 'Poppins', fontSize: 10,
            fontWeight: FontWeight.w500, color: textSecondary),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  DARK THEME — rich navy, not flat black
  // ══════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tenantPrimary,
        primary: tenantPrimary,
        surface: darkSurface,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 18,
            fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.zero,
      ),
      dividerColor: darkDivider,
      drawerTheme: const DrawerThemeData(backgroundColor: darkSurface),
      popupMenuTheme: PopupMenuThemeData(
        color: darkCard,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(fontFamily: 'Poppins',
            fontSize: 13, color: darkTextPrimary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 18,
            fontWeight: FontWeight.w700, color: darkTextPrimary),
        contentTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
            color: darkTextSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkInput,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
            color: darkTextSecondary),
        side: const BorderSide(color: darkDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: darkDivider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: darkTextPrimary,
          textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkDivider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkDivider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: tenantPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: statusInactive)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: statusInactive, width: 1.5)),
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
            color: darkTextHint),
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
            color: darkTextSecondary),
        errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
            color: statusInactive),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: tenantPrimary,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 10,
            fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 10),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: 'Poppins', fontSize: 32,
            fontWeight: FontWeight.w800, color: darkTextPrimary),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontSize: 26,
            fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineMedium:TextStyle(fontFamily: 'Poppins', fontSize: 22,
            fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge:    TextStyle(fontFamily: 'Poppins', fontSize: 18,
            fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleMedium:   TextStyle(fontFamily: 'Poppins', fontSize: 16,
            fontWeight: FontWeight.w500, color: darkTextPrimary),
        titleSmall:    TextStyle(fontFamily: 'Poppins', fontSize: 14,
            fontWeight: FontWeight.w500, color: darkTextPrimary),
        bodyLarge:     TextStyle(fontFamily: 'Poppins', fontSize: 15,
            color: darkTextPrimary),
        bodyMedium:    TextStyle(fontFamily: 'Poppins', fontSize: 13,
            color: darkTextSecondary),
        bodySmall:     TextStyle(fontFamily: 'Poppins', fontSize: 12,
            color: darkTextSecondary),
        labelLarge:    TextStyle(fontFamily: 'Poppins', fontSize: 13,
            fontWeight: FontWeight.w600, color: darkTextPrimary),
        labelSmall:    TextStyle(fontFamily: 'Poppins', fontSize: 10,
            fontWeight: FontWeight.w500, color: darkTextSecondary),
      ),
    );
  }
}
