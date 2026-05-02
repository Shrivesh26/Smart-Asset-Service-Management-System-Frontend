import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: AppTheme.adminPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(user),
                  const SizedBox(height: 28),
                  _buildSection(
                    context,
                    title: 'Account',
                    icon: Icons.manage_accounts_rounded,
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        subtitle: 'Update name, photo and bio',
                        color: AppTheme.adminPrimary,
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        subtitle: 'Secure your account',
                        color: AppTheme.adminPrimary,
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.alternate_email_rounded,
                        label: 'Email Preferences',
                        subtitle: 'Manage notifications & alerts',
                        color: AppTheme.adminPrimary,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    title: 'Platform',
                    icon: Icons.tune_rounded,
                    items: [
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        subtitle: 'Push, email, and in-app alerts',
                        color: const Color(0xFF7C3AED),
                        trailing: Switch.adaptive(
                          value: true,
                          onChanged: (_) {},
                          activeColor: AppTheme.adminPrimary,
                        ),
                      ),
                      _SettingsItem(
                        icon: Icons.palette_outlined,
                        label: 'Appearance',
                        subtitle: 'Light / Dark / System',
                        color: const Color(0xFF7C3AED),
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.language_rounded,
                        label: 'Language & Region',
                        subtitle: 'English (US)',
                        color: const Color(0xFF7C3AED),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    title: 'Administration',
                    icon: Icons.admin_panel_settings_rounded,
                    items: [
                      _SettingsItem(
                        icon: Icons.group_outlined,
                        label: 'Admin Users',
                        subtitle: 'Manage platform administrators',
                        color: AppTheme.tenantPrimary,
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.history_rounded,
                        label: 'Audit Logs',
                        subtitle: 'View all platform activity',
                        color: AppTheme.tenantPrimary,
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.security_rounded,
                        label: 'Security Settings',
                        subtitle: '2FA, session management',
                        color: AppTheme.tenantPrimary,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    title: 'Support',
                    icon: Icons.help_outline_rounded,
                    items: [
                      _SettingsItem(
                        icon: Icons.help_center_outlined,
                        label: 'Help Center',
                        subtitle: 'FAQs and documentation',
                        color: Colors.teal,
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Contact Support',
                        subtitle: 'Get help from our team',
                        color: Colors.teal,
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.info_outline_rounded,
                        label: 'About',
                        subtitle: 'Version 1.0.0 · Terms · Privacy',
                        color: Colors.teal,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLogoutButton(context),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Platform v1.0.0',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.adminPrimary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.gradientForRole('admin'),
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.statusActive,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge('Platform Admin', AppTheme.adminPrimary),
                    const SizedBox(width: 6),
                    _buildBadge('Active', AppTheme.statusActive),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.edit_outlined, color: AppTheme.adminPrimary, size: 20),
            tooltip: 'Edit profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 15),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 56,
            ),
            itemBuilder: (_, i) => _buildSettingsTile(items[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(_SettingsItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              item.trailing ??
                  (item.onTap != null
                      ? const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppTheme.textSecondary,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _confirmLogout(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.statusInactive.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.statusInactive.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.statusInactive,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.statusInactive,
                      ),
                    ),
                    Text(
                      'Sign out of your account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: AppTheme.statusInactive,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.statusInactive,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: AppTheme.statusInactive, size: 22),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins', color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusInactive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Yes, Logout',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthService>().logout();
    }
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    this.trailing,
    this.onTap,
  });
}