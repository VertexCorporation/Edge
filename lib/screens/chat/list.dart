import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../widgets/appbar.dart';

import '../account.dart';
import '../../services/chat.dart';
import 'details.dart';
import 'create/group.dart';
import 'create/community.dart';
import 'community.dart';
import '../../widgets/fog.dart';
import '../../routes.dart';
import 'package:edge/l10n/app_localizations.dart';

class ChatListScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userEmail;
  final bool isVertex;

  const ChatListScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.isVertex,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _communitiesScrollController = ScrollController();
  TabController? _tabController;
  
  late Stream<List<Map<String, dynamic>>> _recentChatsStream;
  late Stream<List<Map<String, dynamic>>> _communitiesStream;
  
  // Suggested Users State
  final List<Map<String, dynamic>> _suggestedUsers = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingUsers = false;
  bool _hasMoreUsers = true;
  bool _showSuggestions = false;
  
  // Phone contacts cache
  List<Contact> _phoneContacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recentChatsStream = _chatService.getRecentChats();
    _communitiesStream = _chatService.getCommunities();
    _initKeys();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initKeys() async {
    try {
      await _chatService.initializeKeys();
      if (!kIsWeb) {
        if (await FlutterContacts.permissions.request(PermissionType.read) == PermissionStatus.granted) {
          _phoneContacts = await FlutterContacts.getAll(
            properties: {ContactProperty.phone, ContactProperty.email},
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing: $e');
    }
  }

  void _onScroll() {
    if (_showSuggestions && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchSuggestedUsers();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
          _suggestedUsers.clear();
          _lastDocument = null;
          _hasMoreUsers = true;
          _showSuggestions = true; // Automatically show suggestions when searching
        });
        _fetchSuggestedUsers();
      }
    });
  }

  Future<void> _fetchSuggestedUsers() async {
    if (_isLoadingUsers || !_hasMoreUsers) return;
    setState(() => _isLoadingUsers = true);

    try {
      final result = await _chatService.getUsersPaginated(
        lastDocument: _lastDocument,
        limit: 20,
        searchQuery: _searchQuery,
      );

      if (mounted) {
        List<Map<String, dynamic>> newUsers = List<Map<String, dynamic>>.from(result['users']);
        
        // Sorting logic: if in phone contacts, bump to top
        if (_phoneContacts.isNotEmpty) {
          final phones = _phoneContacts.expand((c) => c.phones).map((p) => p.number.replaceAll(RegExp(r'\D'), '')).toList();
          final emails = _phoneContacts.expand((c) => c.emails).map((e) => e.address.toLowerCase()).toList();

          newUsers.sort((a, b) {
            final aEmail = (a['email'] ?? '').toString().toLowerCase();
            final bEmail = (b['email'] ?? '').toString().toLowerCase();
            final aPhone = (a['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
            final bPhone = (b['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
            
            final aInContacts = emails.contains(aEmail) || (aPhone.isNotEmpty && phones.contains(aPhone));
            final bInContacts = emails.contains(bEmail) || (bPhone.isNotEmpty && phones.contains(bPhone));

            if (aInContacts && !bInContacts) return -1;
            if (!aInContacts && bInContacts) return 1;
            
            final aName = (a['name'] ?? a['username'] ?? '').toString().toLowerCase();
            final bName = (b['name'] ?? b['username'] ?? '').toString().toLowerCase();
            return aName.compareTo(bName);
          });
        } else {
          // Just alphabetize
          newUsers.sort((a, b) {
            final aName = (a['name'] ?? a['username'] ?? '').toString().toLowerCase();
            final bName = (b['name'] ?? b['username'] ?? '').toString().toLowerCase();
            return aName.compareTo(bName);
          });
        }

        setState(() {
          _suggestedUsers.addAll(newUsers);
          _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          _hasMoreUsers = result['hasMore'] as bool;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _communitiesScrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VertexAppBar(
        scrollController: _scrollController,
        titleAlignToActions: true,
        trailingEdgePadding: 12,
        leadingActions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SlideLeftRoute(
                  page: Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: const VertexAppBar(leadingMode: VertexLeadingMode.back),
                    body: AccountScreen(
                      userName: widget.userName,
                      userRole: widget.userRole,
                      userEmail: widget.userEmail,
                    ),
                  ),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.isDarkUi
                      ? AppColors.senaryColor.withValues(alpha: 0.35)
                      : AppColors.senaryColor.withValues(alpha: 0.2),
                  child: Text(
                    widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isVertex)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.senaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            AppLocalizations.of(context)!.appName,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              child: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: isDark ? Colors.white : Colors.black,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SlideRightRoute(page: const CreateGroupScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.senaryColor,
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isSearching
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchUser,
                            hintStyle: GoogleFonts.inter(color: AppColors.tertiaryColor),
                            prefixIcon: Icon(Icons.search, color: AppColors.tertiaryColor),
                            filled: true,
                            fillColor: isDark ? Colors.white10 : Colors.black12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.senaryColor,
                        unselectedLabelColor: AppColors.tertiaryColor,
                        indicatorColor: AppColors.senaryColor,
                        tabs: const [
                          Tab(text: "Sohbetler"),
                          Tab(text: "Topluluklar"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // 1. Sohbetler Tab
                            ScrollFog(
                              scrollController: _scrollController,
                              color: AppColors.background,
                              child: CustomScrollView(
                                controller: _scrollController,
                                slivers: [
                                  // Recent Chats Section
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                                      child: Text(
                                        AppLocalizations.of(context)!.chats,
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildRecentChatsStream(brightness, isDark),

                                  // Suggested Users Button
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showSuggestions = !_showSuggestions;
                                          });
                                          if (_showSuggestions && _suggestedUsers.isEmpty) {
                                            _fetchSuggestedUsers();
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.senaryColor.withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person_add,
                                                size: 16,
                                                color: AppColors.senaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Kişiler',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.senaryColor,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              _showSuggestions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                              color: AppColors.senaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Suggested Users List
                                  if (_showSuggestions)
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          if (index == _suggestedUsers.length) {
                                            return const SizedBox.shrink();
                                          }

                                          final user = _suggestedUsers[index];
                                          return _buildUserTile(user, brightness, isDark);
                                        },
                                        childCount: _suggestedUsers.length + (_hasMoreUsers ? 1 : 0),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // 2. Topluluklar Tab
                            _buildCommunitiesTab(brightness, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    );
  }

  Widget _buildCommunitiesTab(Brightness brightness, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                SlideRightRoute(page: const CreateCommunityScreen()),
              );
            },
            icon: const Icon(Icons.group_add, color: Colors.white),
            label: Text(AppLocalizations.of(context)!.createNewCommunity, style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.senaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _communitiesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final comms = snapshot.data ?? [];
              if (comms.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.notJoinedAnyCommunity,
                    style: TextStyle(color: AppColors.tertiaryColor, fontStyle: FontStyle.italic),
                  ),
                );
              }
              return ScrollFog(
                scrollController: _communitiesScrollController,
                color: AppColors.background,
                child: ListView.builder(
                  controller: _communitiesScrollController,
                  itemCount: comms.length,
                  itemBuilder: (context, index) {
                    final comm = comms[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondaryColor,
                        child: Icon(Icons.groups, color: AppColors.senaryColor),
                      ),
                      title: Text(comm['name'] ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      subtitle: Text(comm['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.tertiaryColor)),
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideRightRoute(
                            page: CommunityDetailScreen(community: comm),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChatsStream(Brightness brightness, bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _recentChatsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Text(
                'Henüz kimseyle konuşmadınız, hemen sohbete başlayın.',
                style: GoogleFonts.inter(
                  color: AppColors.tertiaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final chat = chats[index];
              if (chat['isGroup'] == true) {
                return _buildUserTile({
                  'uid': '', // no single user
                  'chatId': chat['chatId'],
                  'name': chat['groupName'],
                  'isGroup': true,
                }, brightness, isDark);
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(chat['otherUserId']).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  userData['uid'] = userSnapshot.data!.id; // ensure ID is passed
                  return _buildUserTile(userData, brightness, isDark);
                },
              );
            },
            childCount: chats.length,
          ),
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, Brightness brightness, bool isDark) {
    final isOnline = user['isOnline'] == true;
    final isGroup = user['isGroup'] == true;
    final chatId = user['chatId'];

    String displayName = (user['name'] ?? '').toString().trim();
    if (displayName.isEmpty) {
      displayName = isGroup 
          ? 'İsimsiz Grup' 
          : (user['username'] ?? user['email'] ?? AppLocalizations.of(context)!.anonymousUser).toString().trim();
    }
    
    // Some endpoints may return 'uid' or 'userId' or 'id'
    final uid = user['uid'] ?? user['userId'] ?? user['id'] ?? '';

    return Card(
      color: AppColors.secondaryColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.senaryColor.withValues(alpha: 0.2),
                child: Text(
                  displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    color: AppColors.senaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            displayName,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: user['username'] != null
              ? Text(
                  '@${user['username']}',
                  style: GoogleFonts.inter(
                    color: AppColors.tertiaryColor,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.tertiaryColor,
            size: 16,
          ),
          onTap: () {
            if (!isGroup && uid.isEmpty) return;
            Navigator.push(
              context,
              SlideRightRoute(
                page: ChatDetailScreen(
                  title: displayName,
                  receiverId: isGroup ? null : uid,
                  chatId: isGroup ? chatId : null,
                  isGroup: isGroup,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
