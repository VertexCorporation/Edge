import 'package:flutter/material.dart';
import 'package:edge/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../widgets/card.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../services/auth.dart';
import '../widgets/fog.dart';

/// Account screen - right tab
/// Shows user profile, settings, and logout
class AccountScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userEmail;

  const AccountScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userEmail,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final isDarkTheme = AppColors.currentTheme == 'dark';

    return SafeArea(
      child: ScrollFog(
        scrollController: _scrollController,
        color: AppColors.background,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GradientText(
              'Hesap',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.profileInfoAndSettings,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.tertiaryColor,
              ),
            ),
            const SizedBox(height: 28),

            // Profile card
            _buildProfileCard(brightness, isDark),
            const SizedBox(height: 20),

            // Account info
            _buildInfoSection(brightness, isDark),
            const SizedBox(height: 20),

            // Settings
            _buildSettingsSection(brightness, isDark, isDarkTheme),
            const SizedBox(height: 20),

            // About section
            _buildAboutSection(brightness, isDark),
            const SizedBox(height: 28),

            // Logout button
            VertexButton.outline(
              label: AppLocalizations.of(context)!.logout,
              icon: Icons.logout_rounded,
              width: double.infinity,
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProfileCard(Brightness brightness, bool isDark) {
    return VertexCard(
      animatedBorder: true,
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF2F6BF5), Color(0xFF00E5FF)]),
            ),
            child: Center(
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : 'V',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.primaryColor.inverted
                        : AppColors.primaryColor.inverted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.userRole,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.vertexMember,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Brightness brightness, bool isDark) {
    return VertexCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.accountInfo,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.primaryColor.inverted
                  : AppColors.primaryColor.inverted,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'E-posta',
            value: widget.userEmail,
            brightness: brightness,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Rol',
            value: widget.userRole,
            brightness: brightness,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildInfoRow(
            icon: Icons.verified_outlined,
            label: 'Durum',
            value: 'Doğrulanmış Üye',
            brightness: brightness,
            valueColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Brightness brightness,
    Color? valueColor,
  }) {
    final isDark = brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.tertiaryColor,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.tertiaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ??
                    (isDark
                        ? AppColors.primaryColor.inverted
                        : AppColors.primaryColor.inverted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection(Brightness brightness, bool isDark, bool isDarkTheme) {
    return VertexCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ayarlar',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.primaryColor.inverted
                  : AppColors.primaryColor.inverted,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: AppLocalizations.of(context)!.darkTheme,
            subtitle: isDarkTheme ? 'Aktif' : 'Pasif',
            brightness: brightness,
            trailing: Switch.adaptive(
              value: isDarkTheme,
              onChanged: (value) {
                context.read<ThemeProvider>().changeTheme(value ? 'dark' : 'light');
              },
              activeTrackColor: isDark
                  ? AppColors.senaryColor
                  : AppColors.senaryColor,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _buildSettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirimler',
            subtitle: 'Açık',
            brightness: brightness,
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Brightness brightness,
    required Widget trailing,
  }) {
    final isDark = brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.tertiaryColor,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.primaryColor.inverted
                      : AppColors.primaryColor.inverted,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildAboutSection(Brightness brightness, bool isDark) {
    return VertexCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hakkında',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.primaryColor.inverted
                  : AppColors.primaryColor.inverted,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.info_outline_rounded,
            label: 'Uygulama',
            value: 'Vertex Edge v1.0.0',
            brightness: brightness,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildInfoRow(
            icon: Icons.business_rounded,
            label: 'Şirket',
            value: 'Vertex Corporation',
            brightness: brightness,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildInfoRow(
            icon: Icons.language_rounded,
            label: 'Website',
            value: 'vertexishere.com',
            brightness: brightness,
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark
              ? AppColors.background
              : AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? AppColors.border
                  : AppColors.border,
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.logout,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            AppLocalizations.of(context)!.logoutConfirmation,
            style: GoogleFonts.inter(
              color: AppColors.tertiaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: GoogleFonts.inter(
                  color: AppColors.tertiaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.of(context)!.logout,
                style: GoogleFonts.inter(
                  color: AppColors.septenaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _authService.signOut();
    }
  }
}
