import 'package:edge/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/role.dart';
import '../../routes.dart';
import '../../services/auth.dart';
import '../../services/chat.dart';
import '../../theme.dart';
import '../../widgets/appbar.dart';
import 'create/group.dart';
import 'details.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> community;
  final String userRole;
  final String userEmail;

  const CommunityDetailScreen({
    super.key,
    required this.community,
    required this.userRole,
    required this.userEmail,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final ChatService _chatService = ChatService();
  late final bool _isAdmin;
  late final bool _canOpenGroups;
  late final bool _canCreateGroups;
  late final bool _canDeleteGroups;

  @override
  void initState() {
    super.initState();
    final admins = List<String>.from(widget.community['admins'] ?? []);
    _isAdmin = admins.contains(_chatService.currentUserId);
    final isBootstrap = AuthService.isBootstrapAdminEmail(widget.userEmail);
    _canOpenGroups = UserRole.canOpenGroups(widget.userRole) || isBootstrap;
    _canCreateGroups = UserRole.canCreateGroups(widget.userRole) || isBootstrap;
    _canDeleteGroups = UserRole.canDeleteGroups(widget.userRole) || isBootstrap;
  }

  bool get _isDarkTheme => AppColors.isDarkUi;

  Color get _primaryTextColor =>
      _isDarkTheme ? Colors.white : Colors.black;

  Color get _secondaryTextColor =>
      _isDarkTheme ? Colors.white70 : Colors.black87;

  String get _communityId => widget.community['id'] as String;

  String get _communityName => widget.community['name'] as String? ?? 'Topluluk';

  String get _communityDescription =>
      widget.community['description'] as String? ?? '';

  String? get _announcementGroupId =>
      widget.community['announcementGroupId'] as String?;

  void _openChat({
    required String chatId,
    required String title,
    bool isAnnouncementGroup = false,
  }) {
    if (!_canOpenGroups) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu grubu yalnızca Yönetici ve Mod açabilir.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      SlideRightRoute(
        page: ChatDetailScreen(
          chatId: chatId,
          isGroup: true,
          title: title,
          isAnnouncementGroup: isAnnouncementGroup,
          isAdmin: _isAdmin,
          canDeleteGroup: _canDeleteGroups,
        ),
      ),
    );
  }

  void _openCreateGroup() {
    if (!_canCreateGroups) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grup oluşturmak için Yönetici veya Mod olmalısın.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      SlideRightRoute(
        page: CreateGroupScreen(communityId: _communityId),
      ),
    );
  }

  Widget _buildDescriptionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: _isDarkTheme ? Colors.white10 : Colors.black12,
      child: Text(
        _communityDescription,
        style: TextStyle(color: _secondaryTextColor),
      ),
    );
  }

  bool _isAnnouncementGroup(Map<String, dynamic> group) {
    if (group['isAnnouncementGroup'] == true) return true;
    final groupId = group['chatId'] as String?;
    return groupId != null && groupId == _announcementGroupId;
  }

  Widget _buildAnnouncementTile(
    AppLocalizations l10n,
    List<Map<String, dynamic>> groups,
  ) {
    String? groupId = _announcementGroupId;
    groupId ??= groups
        .cast<Map<String, dynamic>>()
        .where((g) => g['isAnnouncementGroup'] == true)
        .map((g) => g['chatId'] as String?)
        .whereType<String>()
        .firstOrNull;

    if (groupId == null) return const SizedBox.shrink();
    final announcementId = groupId!;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.senaryColor.withValues(alpha: 0.2),
        child: Icon(Icons.campaign, color: AppColors.senaryColor),
      ),
      title: Text(
        l10n.announcements,
        style: TextStyle(
          color: _primaryTextColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        l10n.onlyAdminsCanMessage,
        style: TextStyle(color: AppColors.tertiaryColor, fontSize: 12),
      ),
      onTap: () => _openChat(
        chatId: announcementId,
        title: l10n.announcements,
        isAnnouncementGroup: true,
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group) {
    final groupName = group['groupName'] as String? ?? 'Grup';
    final chatId = group['chatId'] as String;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.secondaryColor.withValues(alpha: 0.2),
        child: Icon(Icons.group, color: AppColors.senaryColor),
      ),
      title: Text(
        groupName,
        style: TextStyle(
          color: _primaryTextColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => _openChat(chatId: chatId, title: groupName),
    );
  }

  Widget _buildGroupsSection(AppLocalizations l10n) {
    return Expanded(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getCommunityGroups(_communityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];
          final filteredGroups =
              groups.where((group) => !_isAnnouncementGroup(group)).toList();

          return Column(
            children: [
              _buildAnnouncementTile(l10n, groups),
              if (_announcementGroupId != null ||
                  groups.any((g) => g['isAnnouncementGroup'] == true))
                const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Gruplar',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.senaryColor,
                  ),
                ),
              ),
              if (filteredGroups.isEmpty)
                Expanded(
                  child: Center(child: Text(l10n.noGroupsInCommunity)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) =>
                        _buildGroupTile(filteredGroups[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: VertexAppBar(
        leadingMode: VertexLeadingMode.back,
        title: Text(
          _communityName,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: _canCreateGroups
            ? [
                IconButton(
                  icon: const Icon(Icons.group_add, color: Colors.white),
                  onPressed: _openCreateGroup,
                  tooltip: 'Yeni Grup',
                ),
              ]
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescriptionBanner(),
          Expanded(child: _buildGroupsSection(l10n)),
        ],
      ),
    );
  }
}
