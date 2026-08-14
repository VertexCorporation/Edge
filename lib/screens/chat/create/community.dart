import 'package:flutter/material.dart';
import 'package:edge/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../../../widgets/appbar.dart';
import '../../../widgets/button.dart';
import '../../../services/chat.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final ChatService _chatService = ChatService();
  bool _isLoading = false;

  final List<String> _selectedUserIds = [];
  List<Map<String, dynamic>> _suggestedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await _chatService.listGroupEligibleUsers();
    if (mounted) {
      setState(() => _suggestedUsers = users);
    }
  }

  Future<void> _createCommunity() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _chatService.createCommunity(
        name,
        _descController.text.trim(),
        _selectedUserIds,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error creating community: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: VertexAppBar(
        leadingMode: VertexLeadingMode.back,
        title: Text(
          "Yeni Topluluk",
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.communityName,
                  labelStyle: TextStyle(color: AppColors.tertiaryColor),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.black12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  labelStyle: TextStyle(color: AppColors.tertiaryColor),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.black12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                "Kişileri Ekle",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _suggestedUsers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _suggestedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _suggestedUsers[index];
                          final uid = user['id'] as String?;
                          if (uid == null || uid == _chatService.currentUserId) return const SizedBox.shrink();

                          final isSelected = _selectedUserIds.contains(uid);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? AppColors.senaryColor : (isDark ? Colors.white24 : Colors.black12),
                              child: isSelected ? const Icon(Icons.check, color: Colors.white) : const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              user['name'] ?? user['username'] ?? '',
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            ),
                            subtitle: Text(
                              user['email'] ?? '',
                              style: TextStyle(color: AppColors.tertiaryColor),
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
              const SizedBox(height: 16),
              VertexButton(
                onPressed: _isLoading || _nameController.text.trim().isEmpty ? null : _createCommunity,
                label: "Oluştur",
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
