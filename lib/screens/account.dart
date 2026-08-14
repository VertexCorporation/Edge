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
import '../routes.dart';
import 'patch_notes.dart';

/// Account screen - profile, settings, and logout
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

  bool get _isDarkTheme => AppColors.currentTheme == 'dark';

  Color get _primaryText =>
      _isDarkTheme ? Colors.white : AppColors.primaryColor.inverted;

  Color get _profileCardColor => _isDarkTheme
      ? const Color(0xFF0D2048)
      : AppColors.secondaryColor;

  Color get _profileCardBorder => _isDarkTheme
      ? AppColors.senaryColor.withValues(alpha: 0.35)
      : AppColors.border;

  Widget _sectionDivider({EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 12)}) {
    return Padding(
      padding: padding,
      child: Divider(
        height: 1,
        color: _isDarkTheme ? AppColors.border : null,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.watch<ThemeProvider>();

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: ScrollFog(
          scrollController: _scrollController,
          color: AppColors.background,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildInfoSection(),
                const SizedBox(height: 20),
                _buildSettingsSection(),
                const SizedBox(height: 20),
                _buildAboutSection(),
                const SizedBox(height: 28),
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
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: _profileCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _profileCardBorder),
      ),
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2F6BF5), Color(0xFF00E5FF)],
              ),
              border: Border.all(
                color: _isDarkTheme
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: _isDarkTheme
                  ? [
                      BoxShadow(
                        color: AppColors.senaryColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : 'V',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
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
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isDarkTheme
                        ? AppColors.senaryColor.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.userRole,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _isDarkTheme ? AppColors.senaryColor : AppColors.tertiaryColor,
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

  Widget _buildInfoSection() {
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
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'E-posta',
            value: widget.userEmail,
          ),
          _sectionDivider(),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Rol',
            value: widget.userRole,
          ),
          _sectionDivider(),
          _buildInfoRow(
            icon: Icons.verified_outlined,
            label: 'Durum',
            value: 'Doğrulanmış Üye',
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
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.senaryColor),
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
                color: valueColor ?? _primaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
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
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: AppLocalizations.of(context)!.darkTheme,
            subtitle: _isDarkTheme ? 'Aktif' : 'Pasif',
            trailing: Switch.adaptive(
              value: _isDarkTheme,
              onChanged: (value) {
                context.read<ThemeProvider>().changeTheme(value ? 'dark' : 'light');
              },
              activeTrackColor: AppColors.senaryColor,
              activeThumbColor: Colors.white,
            ),
          ),
          _sectionDivider(padding: const EdgeInsets.symmetric(vertical: 8)),
          _buildSettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirimler',
            subtitle: 'Açık',
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
    required Widget trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.senaryColor),
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
                  color: _primaryText,
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

  Widget _buildAboutSection() {
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
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.info_outline_rounded,
            label: 'Uygulama',
            value: 'Vertex Edge v1.0.5',
          ),
          _sectionDivider(),
          _buildInfoRow(
            icon: Icons.business_rounded,
            label: 'Şirket',
            value: 'Vertex Corporation',
          ),
          _sectionDivider(),
          _buildInfoRow(
            icon: Icons.language_rounded,
            label: 'Website',
            value: 'vertexishere.com',
          ),
          _sectionDivider(),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                SlideRightRoute(page: const PatchNotesScreen()),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.new_releases_outlined, size: 18, color: AppColors.senaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patch Notes',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _primaryText,
                          ),
                        ),
                        Text(
                          'Güncelleme geçmişi',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.tertiaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.tertiaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          title: Text(
            AppLocalizations.of(context)!.logout,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.logoutConfirmation,
            style: GoogleFonts.inter(color: AppColors.tertiaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: GoogleFonts.inter(color: AppColors.tertiaryColor),
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
