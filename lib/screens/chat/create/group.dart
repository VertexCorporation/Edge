import 'package:flutter/material.dart';
import 'package:edge/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../../../services/chat.dart';
import '../../../widgets/appbar.dart';

class CreateGroupScreen extends StatefulWidget {
  final String? communityId;

  const CreateGroupScreen({super.key, this.communityId});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _chatService.listGroupEligibleUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Kullanıcılar yüklenemedi: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterGroupName)),
      );
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectAtLeastOnePerson)),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await _chatService.createGroupChat(
        groupName,
        _selectedUserIds.toList(),
        communityId: widget.communityId,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.groupCreationError}. Tekrar dene.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredUsers = _users.where((u) {
      final q = _searchController.text.toLowerCase();
      final name = (u['name'] ?? '').toString().toLowerCase();
      final username = (u['username'] ?? '').toString().toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VertexAppBar(
        leadingMode: VertexLeadingMode.back,
        titleText: 'Yeni Grup',
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Oluştur',
                style: GoogleFonts.inter(
                  color: AppColors.senaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.groupName,
                filled: true,
                fillColor: AppColors.secondaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchContact,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.secondaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          'Davet edilecek kullanıcı bulunamadı',
                          style: GoogleFonts.inter(color: AppColors.tertiaryColor),
                        ),
                      )
                    : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final uid = (user['id'] ?? user['userId'])?.toString();
                      if (uid == null || uid.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final isSelected = _selectedUserIds.contains(uid);

                      String displayName = (user['name'] ?? '').toString().trim();
                      if (displayName.isEmpty) {
                        displayName = (user['username'] ?? user['email'] ?? 'İsimsiz').toString().trim();
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.senaryColor.withValues(alpha: 0.2),
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              color: AppColors.senaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '@${user['username']}',
                          style: GoogleFonts.inter(
                            color: AppColors.tertiaryColor,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.add(uid);
                              } else {
                                _selectedUserIds.remove(uid);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(uid);
                            } else {
                              _selectedUserIds.add(uid);
                            }
                          });
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
