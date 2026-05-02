class AppConstants {
  // ── App Info ────────────────────────────────────────────────────────
  static const String appName = 'SmartAsset';
  static const String appVersion = '1.0.0';

  // ── API Base URL ────────────────────────────────────────────────────
  // Replace with your actual backend URL
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // ── SharedPreferences Keys ──────────────────────────────────────────
  static const String keyToken = 'auth_token';
  static const String keyRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyIsLoggedIn = 'is_logged_in';

  // ── Roles ───────────────────────────────────────────────────────────
  static const String roleAdmin = 'admin';
  static const String roleTenant = 'tenant';
  static const String roleProvider = 'service_provider';
  static const String roleUser = 'user';

  // ── Booking / Order Status ──────────────────────────────────────────
  // These are the exact status strings used across admin, provider, user
  static const String statusRequested = 'Requested';
  static const String statusAssigned = 'Assigned';
  static const String statusAccepted = 'Accepted';
  static const String statusInProgress = 'In Progress';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
  static const String statusResolved = statusCancelled;

  // ── Provider Job Status (provider updates these) ────────────────────
  static const List<String> providerStatuses = [
    statusAccepted,
    statusInProgress,
    statusCompleted,
    statusCancelled,
  ];

  // ── Asset Status ────────────────────────────────────────────────────
  static const String assetAvailable = 'available';
  static const String assetAssigned = 'assigned';
  static const String assetMaintenance = 'maintenance';
  static const List<String> assetStatuses = [
    assetAvailable,
    assetAssigned,
    assetMaintenance,
  ];

  // ── Asset Categories ───────────────────────────────────────────────
  static const List<String> assetCategories = [
    'Tools',
    'Equipment',
    'Electrical',
    'Plumbing',
    'HVAC',
    'IT Hardware',
    'Safety Gear',
    'Vehicles',
    'Furniture',
    'Spare Parts',
    'Other',
  ];

  // ── Service Categories ──────────────────────────────────────────────
  static const List<String> serviceCategories = [
    'beauty',
    'wellness',
    'healthcare',
    'fitness',
    'consulting',
    'automotive',
    'home_services',
    'other',
  ];

  // ── Skill Categories (for Provider registration by Admin) ───────────
  static const List<String> skillCategories = [
    'HVAC Technician',
    'Electrician',
    'Plumber',
    'IT Specialist',
    'Security Technician',
    'General Repair',
    'Carpenter',
    'Painter',
    'Senior Technician',
    'Maintenance Tech',
    'Other',
  ];

  // ── Experience Options ──────────────────────────────────────────────
  static const List<String> experienceOptions = [
    'Less than 1 year',
    '1 - 2 years',
    '2 - 5 years',
    '5 - 10 years',
    '10+ years',
  ];

  // ── Time Slots for Booking ──────────────────────────────────────────
  static const List<String> timeSlots = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
  ];

  // ── Business types — matches Tenant schema enum ───────────────────────
  static const List<String> businessTypes = [
    // Home & Local Services
    'home services',
    'cleaning services',
    'repair & maintenance',

    // Healthcare
    'medical clinic',
    'dental clinic',

    // Automotive
    'car service center',
    'bike service center',
    'car wash & detailing',

    // Beauty & Wellness
    'salon',
    'wellness',
    'beauty clinic',

    // Other
    'other',
  ];

  // ── Notification Types ──────────────────────────────────────────────
  static const String notifNewBooking = 'new_booking';
  static const String notifAssignment = 'assignment';
  static const String notifStatusUpdate = 'status_update';
  static const String notifCompleted = 'completed';

  // ── Forgot Password Rules ───────────────────────────────────────────
  // Admin  → reset via email
  // User   → reset via email
  // Provider → contact admin (no self-reset)
  static const String providerForgotMsg =
      'Provider passwords can only be reset by your Admin.\n'
      'Please contact your store administrator for assistance.';

  // ── UI Constants ────────────────────────────────────────────────────
  static const double paddingPage = 20.0;
  static const double paddingCard = 16.0;
  static const double radiusCard = 16.0;
  static const double radiusButton = 12.0;
  static const double radiusInput = 12.0;
  static const double radiusChip = 20.0;
}
