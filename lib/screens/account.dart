import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/card.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../services/auth.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
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
              'Profil bilgileri ve ayarlar',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: VertexColors.textMuted(brightness),
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
            _buildSettingsSection(brightness, isDark),
            const SizedBox(height: 20),

            // About section
            _buildAboutSection(brightness, isDark),
            const SizedBox(height: 28),

            // Logout button
            VertexButton.outline(
              label: 'Çıkış Yap',
              icon: Icons.logout_rounded,
              width: double.infinity,
              onPressed: _handleLogout,
            ),
          ],
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
              gradient: VertexColors.gradientMain(brightness),
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
                        ? VertexColors.textMainDark
                        : VertexColors.textMainLight,
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
                      color: VertexColors.textMuted(brightness),
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
                        color: VertexColors.success,
                        boxShadow: [
                          BoxShadow(
                            color: VertexColors.success.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vertex Üyesi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: VertexColors.success,
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
            'Hesap Bilgileri',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? VertexColors.textMainDark
                  : VertexColors.textMainLight,
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
            valueColor: VertexColors.success,
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
          color: VertexColors.textMuted(brightness),
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
                color: VertexColors.textMuted(brightness),
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
                        ? VertexColors.textMainDark
                        : VertexColors.textMainLight),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection(Brightness brightness, bool isDark) {
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
                  ? VertexColors.textMainDark
                  : VertexColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Koyu Tema',
            subtitle: isDark ? 'Aktif' : 'Pasif',
            brightness: brightness,
            trailing: Switch.adaptive(
              value: isDark,
              onChanged: (value) {
                // Theme toggle will be handled by parent
              },
              activeTrackColor: isDark
                  ? VertexColors.primaryDark
                  : VertexColors.primaryLight,
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
              color: VertexColors.textMuted(brightness),
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
          color: VertexColors.textMuted(brightness),
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
                      ? VertexColors.textMainDark
                      : VertexColors.textMainLight,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: VertexColors.textMuted(brightness),
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
                  ? VertexColors.textMainDark
                  : VertexColors.textMainLight,
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
              ? VertexColors.bgCardDark
              : VertexColors.bgCardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? VertexColors.borderDark
                  : VertexColors.borderLight,
            ),
          ),
          title: Text(
            'Çıkış Yap',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
            style: GoogleFonts.inter(
              color: VertexColors.textMuted(Theme.of(context).brightness),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'İptal',
                style: GoogleFonts.inter(
                  color: VertexColors.textMuted(Theme.of(context).brightness),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Çıkış Yap',
                style: GoogleFonts.inter(
                  color: VertexColors.error,
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
