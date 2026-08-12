import 'package:flutter/material.dart';
import 'package:edge/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme.dart';
import '../../widgets/appbar.dart';
import '../../services/chat.dart';
import 'details.dart';
import 'create/group.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final ChatService _chatService = ChatService();
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    final admins = List<String>.from(widget.community['admins'] ?? []);
    _isAdmin = admins.contains(_chatService.currentUserId);
  }

  Widget _buildGroupTile(Map<String, dynamic> group, bool isDark) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.secondaryColor.withValues(alpha: 0.2),
        child: Icon(Icons.group, color: AppColors.senaryColor),
      ),
      title: Text(
        group['groupName'] ?? 'Grup',
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: group['chatId'],
              isGroup: true,
              title: group['groupName'] ?? 'Grup',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final communityId = widget.community['id'] as String;

    return Scaffold(
      appBar: VertexAppBar(
        leadingMode: VertexLeadingMode.back,
        title: Text(
          widget.community['name'] ?? 'Topluluk',
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.group_add, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateGroupScreen(communityId: communityId),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.white10 : Colors.black12,
            width: double.infinity,
            child: Text(
              widget.community['description'] ?? '',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          
          // Announcements Group
          if (widget.community['announcementGroupId'] != null)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.senaryColor.withValues(alpha: 0.2),
                child: Icon(Icons.campaign, color: AppColors.senaryColor),
              ),
              title: Text(AppLocalizations.of(context)!.announcements, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              subtitle: Text(AppLocalizations.of(context)!.onlyAdminsCanMessage, style: TextStyle(color: AppColors.tertiaryColor, fontSize: 12)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatId: widget.community['announcementGroupId'],
                      isGroup: true,
                      title: AppLocalizations.of(context)!.announcements,
                      isAnnouncementGroup: true,
                      isAdmin: _isAdmin,
                    ),
                  ),
                );
              },
            ),
          
          const Divider(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Gruplar",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.senaryColor),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getCommunityGroups(communityId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final groups = snapshot.data ?? [];
                
                // Exclude the announcement group from the general list
                final filteredGroups = groups.where((g) => g['chatId'] != widget.community['announcementGroupId']).toList();

                if (filteredGroups.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.noGroupsInCommunity));
                }
                
                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    return _buildGroupTile(filteredGroups[index], isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
