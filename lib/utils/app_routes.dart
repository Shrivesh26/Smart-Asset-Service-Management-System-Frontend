import 'package:go_router/go_router.dart';
import 'package:smart_asset_service/screens/provider/provider_contact_support_screen.dart';
import 'package:smart_asset_service/screens/provider/provider_edit_profile_screen.dart';
import 'package:smart_asset_service/screens/provider/provider_privacy_policy_screen.dart';
import 'package:smart_asset_service/screens/tenant/tenant_edit_profile_screen.dart';
import 'package:smart_asset_service/screens/tenant/tenant_help_support_screen.dart';
import 'package:smart_asset_service/screens/tenant/tenant_privacy_policy_screen.dart';
import 'package:smart_asset_service/screens/user/user_edit_profile_screen.dart';

import '../services/auth_service.dart';
import '../utils/app_constants.dart';

// ── Auth ────────────────────────────────────────────────────────────────
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// ── Platform Admin (new) ────────────────────────────────────────────────
import '../screens/admin/admin_shell.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_tenants_screen.dart';
import '../screens/admin/admin_settings_screen.dart';

// ── Tenant (renamed from admin) ─────────────────────────────────────────
import '../screens/tenant/tenant_shell.dart';
import '../screens/tenant/tenant_dashboard_screen.dart';
import '../screens/tenant/tenant_services_screen.dart';
import '../screens/tenant/tenant_inventory_screen.dart';
import '../screens/tenant/tenant_providers_screen.dart';
import '../screens/tenant/tenant_orders_screen.dart';
import '../screens/tenant/tenant_notifications_screen.dart';
import '../screens/tenant/tenant_settings_screen.dart';
import '../screens/tenant/add_service_screen.dart';
import '../screens/tenant/add_asset_screen.dart';
import '../screens/tenant/add_provider_screen.dart';
import '../screens/tenant/order_detail_screen.dart';
import '../screens/tenant/assign_provider_screen.dart';

// ── Provider ─────────────────────────────────────────────────────────────
import '../screens/provider/provider_shell.dart';
import '../screens/provider/provider_dashboard_screen.dart';
import '../screens/provider/provider_services_screen.dart';
import '../screens/provider/provider_task_detail_screen.dart';
import '../screens/provider/provider_completed_screen.dart';
import '../screens/provider/provider_notifications_screen.dart';
import '../screens/provider/provider_settings_screen.dart';

// ── User ─────────────────────────────────────────────────────────────────
import '../screens/user/user_shell.dart';
import '../screens/user/user_dashboard_screen.dart';
import '../screens/user/user_stores_screen.dart';
import '../screens/user/user_services_screen.dart';
import '../screens/user/book_service_screen.dart';
import '../screens/user/user_order_history_screen.dart';
import '../screens/user/user_order_status_screen.dart';
import '../screens/user/user_notifications_screen.dart';
import '../screens/user/user_settings_screen.dart';

class AppRoutes {
  // ── Auth ───────────────────────────────────────────────────────────
  static const String splash         = '/';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Platform Admin ─────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String adminTenants   = '/admin/tenants';
  static const String adminSettings  = '/admin/settings';

  // ── Tenant ─────────────────────────────────────────────────────────
  static const String tenantDashboard     = '/tenant/dashboard';
  static const String tenantServices      = '/tenant/services';
  static const String tenantInventory     = '/tenant/inventory';
  static const String tenantProviders     = '/tenant/providers';
  static const String tenantOrders        = '/tenant/orders';
  static const String tenantNotifications = '/tenant/notifications';
  static const String tenantSettings      = '/tenant/settings';
  static const String addService          = '/tenant/services/add';
  static const String addAsset            = '/tenant/inventory/add';
  static const String addProvider         = '/tenant/providers/add';
  static const String orderDetail         = '/tenant/orders/:orderId';
  static const String assignProvider      = '/tenant/orders/:orderId/assign';
  static const String tenantEditProfile   = '/tenant/settings/edit-profile';
  static const String tenantHelpSupport   = '/tenant/settings/help-support';
  static const String tenantPrivacyPolicy = '/tenant/settings/privacy-policy';

  // ── Provider ───────────────────────────────────────────────────────
  static const String providerDashboard     = '/provider/dashboard';
  static const String providerServices      = '/provider/services';
  static const String providerTaskDetail    = '/provider/services/:taskId';
  static const String providerCompleted     = '/provider/completed';
  static const String providerNotifications = '/provider/notifications';
  static const String providerSettings      = '/provider/settings';
  static const String providerEditProfile   = '/provider/settings/edit-profile';
  static const String providerContactSupport   = '/provider/settings/contact-support';
  static const String providerPrivacyPolicy = '/provider/settings/privacy-policy';

  // ── User ───────────────────────────────────────────────────────────
  static const String userDashboard      = '/user/dashboard';
  static const String userMarketplace    = '/user/services';
  static const String userStores         = '/user/stores';
  static const String userServices       = '/user/stores/:storeId/services';
  static const String bookService        = '/user/book';
  static const String userOrderHistory   = '/user/orders';
  static const String userOrderStatus    = '/user/orders/:orderId';
  static const String userNotifications  = '/user/notifications';
  static const String userSettings       = '/user/settings';
  static const String userEditProfile     = '/user/settings/edit-profile';
  static const String userHelpSupport    = '/user/settings/help-support';
  static const String userPrivacyPolicy  = '/user/settings/privacy-policy';

  // ── Router factory ─────────────────────────────────────────────────
  static GoRouter router(AuthService authService) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final role       = authService.currentRole;
        final loc        = state.matchedLocation;

        final isAuthRoute = loc == splash
            || loc == login
            || loc.startsWith('/register')
            || loc.startsWith('/forgot-password');

        // Not logged in → force to login
        if (!isLoggedIn && !isAuthRoute) return login;

        // Logged in on auth screen → correct dashboard
        if (isLoggedIn && isAuthRoute) return _homeForRole(role);

        // Cross-role guard — each role can only access its own routes
        if (isLoggedIn && role != null) {
          if (role == AppConstants.roleAdmin) {
            if (loc.startsWith('/tenant'))   return adminDashboard;
            if (loc.startsWith('/provider')) return adminDashboard;
            if (loc.startsWith('/user'))     return adminDashboard;
          }
          if (role == AppConstants.roleTenant) {
            if (loc.startsWith('/admin'))    return tenantDashboard;
            if (loc.startsWith('/provider')) return tenantDashboard;
            if (loc.startsWith('/user'))     return tenantDashboard;
          }
          if (role == AppConstants.roleProvider) {
            if (loc.startsWith('/admin'))    return providerDashboard;
            if (loc.startsWith('/tenant'))   return providerDashboard;
            if (loc.startsWith('/user'))     return providerDashboard;
          }
          if (role == AppConstants.roleUser) {
            if (loc.startsWith('/admin'))    return userDashboard;
            if (loc.startsWith('/tenant'))   return userDashboard;
            if (loc.startsWith('/provider')) return userDashboard;
          }
        }

        return null;
      },

      routes: [
        // ── Auth ───────────────────────────────────────────────────
        GoRoute(path: splash,         builder: (_, __) => const SplashScreen()),
        GoRoute(path: login,          builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: register,
          builder: (_, state) => RegisterScreen(
            role: state.uri.queryParameters['role'] ?? AppConstants.roleTenant,
          ),
        ),
        GoRoute(
          path: forgotPassword,
          builder: (_, state) => ForgotPasswordScreen(
            role: state.uri.queryParameters['role'] ?? AppConstants.roleTenant,
          ),
        ),

        // ── Platform Admin shell ────────────────────────────────────
        ShellRoute(
          builder: (_, __, child) => AdminShell(child: child),
          routes: [
            GoRoute(path: adminDashboard, builder: (_, __) => const AdminDashboardScreen()),
            GoRoute(path: adminTenants,   builder: (_, __) => const AdminTenantsScreen()),
            GoRoute(path: adminSettings,  builder: (_, __) => const AdminSettingsScreen()),
          ],
        ),

        // ── Tenant shell ────────────────────────────────────────────
        ShellRoute(
          builder: (_, __, child) => TenantShell(child: child),
          routes: [
            GoRoute(path: tenantDashboard, builder: (_, __) => const TenantDashboardScreen()),
            GoRoute(
              path: tenantServices,
              builder: (_, __) => const TenantServicesScreen(),
              routes: [
                GoRoute(path: 'add', builder: (_, __) => const AddServiceScreen()),
              ],
            ),
            GoRoute(
              path: tenantInventory,
              builder: (_, __) => const TenantInventoryScreen(),
              routes: [
                GoRoute(path: 'add', builder: (_, __) => const AddAssetScreen()),
              ],
            ),
            GoRoute(
              path: tenantProviders,
              builder: (_, __) => const TenantProvidersScreen(),
              routes: [
                GoRoute(path: 'add', builder: (_, __) => const AddProviderScreen()),
              ],
            ),
            GoRoute(
              path: tenantOrders,
              builder: (_, __) => const TenantOrdersScreen(),
              routes: [
                GoRoute(
                  path: ':orderId',
                  builder: (_, state) => OrderDetailScreen(
                    orderId: state.pathParameters['orderId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'assign',
                      builder: (_, state) => AssignProviderScreen(
                        orderId: state.pathParameters['orderId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(path: tenantNotifications, builder: (_, __) => const TenantNotificationsScreen()),
            GoRoute(path: tenantSettings,      builder: (_, __) => const TenantSettingsScreen()),
            GoRoute(path: tenantEditProfile,   builder: (_, __) => const TenantEditProfileScreen()),
            GoRoute(
              path: tenantHelpSupport,
              builder: (_, __) => const TenantHelpSupportScreen(),
              ),
            GoRoute(
              path: tenantPrivacyPolicy,
              builder: (_, __) => const TenantPrivacyPolicyScreen(),
            ),
          ],
        ),

        // ── Provider shell ──────────────────────────────────────────
        ShellRoute(
          builder: (_, __, child) => ProviderShell(child: child),
          routes: [
            GoRoute(path: providerDashboard, builder: (_, __) => const ProviderDashboardScreen()),
            GoRoute(
              path: providerServices,
              builder: (_, __) => const ProviderServicesScreen(),
              routes: [
                GoRoute(
                  path: ':taskId',
                  builder: (_, state) => ProviderTaskDetailScreen(
                    taskId: state.pathParameters['taskId']!,
                  ),
                ),
              ],
            ),
            GoRoute(path: providerCompleted,     builder: (_, __) => const ProviderCompletedScreen()),
            GoRoute(path: providerNotifications, builder: (_, __) => const ProviderNotificationsScreen()),
            GoRoute(path: providerSettings,      builder: (_, __) => const ProviderSettingsScreen()),
            GoRoute(path: providerEditProfile,   builder: (_, __) => const ProviderEditProfileScreen()),
            GoRoute(
              path: providerContactSupport,
              builder: (_, __) => const ProviderContactSupportScreen(),
            ),
            GoRoute(
              path: providerPrivacyPolicy,
              builder: (_, __) => const ProviderPrivacyPolicyScreen(),
            ),
          ],
        ),

        // ── User shell ──────────────────────────────────────────────
        ShellRoute(
          builder: (_, __, child) => UserShell(child: child),
          routes: [
            GoRoute(path: userDashboard, builder: (_, __) => const UserDashboardScreen()),
            GoRoute(
              path: userMarketplace,
              builder: (_, __) => const UserServicesScreen(storeId: ''),
            ),
            GoRoute(
              path: userStores,
              builder: (_, __) => const UserStoresScreen(),
              routes: [
                GoRoute(
                  path: ':storeId/services',
                  builder: (_, state) => UserServicesScreen(
                    storeId: state.pathParameters['storeId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: bookService,
              builder: (_, state) => BookServiceScreen(
                serviceId: state.uri.queryParameters['serviceId'] ?? '',
                storeId:   state.uri.queryParameters['storeId']   ?? '',
              ),
            ),
            GoRoute(
              path: userOrderHistory,
              builder: (_, __) => const UserOrderHistoryScreen(),
              routes: [
                GoRoute(
                  path: ':orderId',
                  builder: (_, state) => UserOrderStatusScreen(
                    orderId: state.pathParameters['orderId']!,
                  ),
                ),
              ],
            ),
            GoRoute(path: userNotifications, builder: (_, __) => const UserNotificationsScreen()),
            GoRoute(path: userSettings,      builder: (_, __) => const UserSettingsScreen()),
            GoRoute(path: userEditProfile,   builder: (_, __) => const UserEditProfileScreen()),
          ],
        ),
      ],
    );
  }

  static String _homeForRole(String? role) {
    switch (role) {
      case AppConstants.roleAdmin:    return adminDashboard;
      case AppConstants.roleTenant:   return tenantDashboard;
      case AppConstants.roleProvider: return providerDashboard;
      case AppConstants.roleUser:     return userDashboard;
      default:                        return login;
    }
  }
}
