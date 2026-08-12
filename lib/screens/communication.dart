import 'package:flutter/material.dart';
import 'package:edge/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../widgets/card.dart';
import '../widgets/text.dart';

/// Communication screen - left tab
/// Shows contact channels and quick communication options
class CommunicationScreen extends StatefulWidget {
  final String userName;

  const CommunicationScreen({super.key, required this.userName});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<_Channel> _channels = [
    _Channel(
      name: 'Discord Sunucusu',
      description: 'Ekip ile anlık iletişim ve sesli toplantılar',
      icon: Icons.discord,
      color: Color(0xFF5865F2),
      url: 'https://discord.gg/vertex',
    ),
    _Channel(
      name: 'E-posta',
      description: 'Resmi yazışmalar ve dış iletişim',
      icon: Icons.email_outlined,
      color: AppColors.tertiaryColor,
      url: 'mailto:contact@vertexishere.com',
    ),
    _Channel(
      name: 'LinkedIn',
      description: 'Profesyonel ağ ve şirket profili',
      icon: Icons.work_outline_rounded,
      color: Color(0xFF0A66C2),
      url: 'https://www.linkedin.com/company/106897671/',
    ),
    _Channel(
      name: 'Instagram',
      description: 'Sosyal medya ve topluluk paylaşımları',
      icon: Icons.camera_alt_outlined,
      color: Color(0xFFE4405F),
      url: 'https://www.instagram.com/vertex.23/',
    ),
    _Channel(
      name: 'GitHub',
      description: 'Açık kaynak projeler ve kod incelemeleri',
      icon: Icons.code_rounded,
      color: AppColors.tertiaryColor,
      url: 'https://github.com/VertexCorporation',
    ),
  ];

  final List<_TeamMember> _recentContacts = [
    _TeamMember(name: 'Mustafa Çakı', role: 'CEO', initial: 'M'),
    _TeamMember(name: 'Ata Türkçü', role: 'CTO', initial: 'A'),
    _TeamMember(name: 'Murat Coşkun', role: 'Baş Mimar', initial: 'M'),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  GradientText(
                    'İletişim',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.contactVertexTeam,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Quick contacts
                  Text(
                    AppLocalizations.of(context)!.teamMembers,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.primaryColor.inverted
                          : AppColors.primaryColor.inverted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildContactsRow(brightness, isDark),
                  const SizedBox(height: 28),

                  // Channels
                  Text(
                    AppLocalizations.of(context)!.communicationChannels,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.primaryColor.inverted
                          : AppColors.primaryColor.inverted,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Channel list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildChannelCard(
                        _channels[index], brightness, isDark),
                  );
                },
                childCount: _channels.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsRow(Brightness brightness, bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recentContacts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final contact = _recentContacts[index];
          return SizedBox(
            width: 72,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      contact.initial,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.primaryColor.inverted
                            : AppColors.primaryColor.inverted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contact.name.split(' ').first,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.primaryColor.inverted
                        : AppColors.primaryColor.inverted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  contact.role,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.tertiaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelCard(
      _Channel channel, Brightness brightness, bool isDark) {
    return VertexCard(
      padding: const EdgeInsets.all(18),
      onTap: () => _launchUrl(channel.url),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: channel.color.withValues(alpha: 0.1),
            ),
            child: Icon(
              channel.icon,
              color: channel.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.primaryColor.inverted
                        : AppColors.primaryColor.inverted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  channel.description,
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
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _Channel {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String url;

  const _Channel({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.url,
  });
}

class _TeamMember {
  final String name;
  final String role;
  final String initial;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.initial,
  });
}
