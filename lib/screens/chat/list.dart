import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/role.dart';
import '../../widgets/appbar.dart';
import '../../widgets/avatar.dart';

import '../account.dart';
import '../../services/chat.dart';
import '../../services/auth.dart';
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
  _OpenChat? _openChat;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _communitiesScrollController = ScrollController();
  TabController? _tabController;
  
  late Stream<List<Map<String, dynamic>>> _recentChatsStream;
  late Stream<List<Map<String, dynamic>>> _communitiesStream;
  
  // Suggested Users State
  final List<Map<String, dynamic>> _suggestedUsers = [];
  final Map<String, Map<String, dynamic>> _partnerCache = {};
  List<Map<String, dynamic>> _recentChats = [];
  StreamSubscription<List<Map<String, dynamic>>>? _recentChatsSub;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingUsers = false;
  bool _hasMoreUsers = true;
  
  // Phone contacts cache
  List<Contact> _phoneContacts = [];

  bool get _canOpenGroups =>
      UserRole.canOpenGroups(widget.userRole) ||
      AuthService.isBootstrapAdminEmail(widget.userEmail);

  bool get _canCreateGroups =>
      UserRole.canCreateGroups(widget.userRole) ||
      AuthService.isBootstrapAdminEmail(widget.userEmail);

  bool get _canDeleteGroups =>
      UserRole.canDeleteGroups(widget.userRole) ||
      AuthService.isBootstrapAdminEmail(widget.userEmail);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final seeAllGroups = UserRole.canSeeAllGroups(widget.userRole);
    _recentChatsStream = _chatService.getRecentChats(seeAllGroups: seeAllGroups);
    _communitiesStream = _chatService.getCommunities(seeAllGroups: seeAllGroups);
    _bindRecentChats();
    _initKeys();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadPeople();
  }

  Future<void> _confirmDeleteGroupFromList(String chatId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Grubu sil'),
          content: Text(
            '"$name" grubunu silmek istediğine emin misin? Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Sil',
                style: TextStyle(color: AppColors.septenaryColor),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _chatService.deleteGroupChat(chatId);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Grup silindi.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Grup silinemedi: $e')),
      );
    }
  }

  @override
  void didUpdateWidget(ChatListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRole != widget.userRole) {
      final seeAllGroups = UserRole.canSeeAllGroups(widget.userRole);
      setState(() {
        _recentChatsStream = _chatService.getRecentChats(seeAllGroups: seeAllGroups);
        _communitiesStream = _chatService.getCommunities(seeAllGroups: seeAllGroups);
      });
      _bindRecentChats();
    }
  }

  void _bindRecentChats() {
    _recentChatsSub?.cancel();
    _recentChatsSub = _recentChatsStream.listen((chats) {
      if (!mounted) return;
      setState(() => _recentChats = chats);
    }, onError: (e) {
      debugPrint('Recent chats listen failed: $e');
    });
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
    if (_searchQuery.isEmpty) return;
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
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
        });
        if (query.isEmpty) {
          _loadPeople();
        } else {
          _fetchSuggestedUsers();
        }
      }
    });
  }

  Future<void> _loadPeople() async {
    try {
      final users = await _chatService.listGroupEligibleUsers();
      if (!mounted) return;
      setState(() {
        _suggestedUsers
          ..clear()
          ..addAll(users);
        _hasMoreUsers = false;
        _isLoadingUsers = false;
      });
    } catch (e) {
      debugPrint('People list failed: $e');
    }
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
    _recentChatsSub?.cancel();
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
    final split = MediaQuery.sizeOf(context).width >= 720;
    final listPane = _buildListPane(brightness, isDark, split);

    if (!split) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(isDark),
        body: SafeArea(child: listPane),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          SizedBox(
            width: 380,
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(isDark, layoutWidth: 380),
                  Expanded(child: listPane),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: _buildChatPane()),
        ],
      ),
    );
  }

  VertexAppBar _buildAppBar(bool isDark, {double? layoutWidth}) {
    return VertexAppBar(
      scrollController: _scrollController,
      layoutWidth: layoutWidth,
      titleAlignToActions: false,
      trailingEdgePadding: 12,
      leadingActions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: _openAccount,
            child: ThemeAvatar(
              name: widget.userName,
              radius: 18,
              isVerified: widget.isVertex,
            ),
          ),
        ),
      ],
      title: AppColors.isBlackTheme
          ? ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.edgeTitleGradient.createShader(bounds),
              child: Text(
                AppLocalizations.of(context)!.appName,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          : Text(
              AppLocalizations.of(context)!.appName,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.edgeTitleColor,
              ),
            ),
      actions: [
        _circleIcon(
          icon: _isSearching ? Icons.close : Icons.search,
          filled: false,
          isDark: isDark,
          onTap: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
        ),
        if (_canCreateGroups) ...[
          const SizedBox(width: 10),
          _circleIcon(
            icon: Icons.groups_outlined,
            filled: false,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                SlideRightRoute(page: const CreateCommunityScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
          _circleIcon(
            icon: Icons.add,
            filled: true,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                SlideRightRoute(page: const CreateGroupScreen()),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _circleIcon({
    required IconData icon,
    required bool filled,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final fg = filled
        ? ThemeAvatar.onAccent()
        : (isDark ? Colors.white : Colors.black);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? AppColors.senaryColor
              : (isDark ? Colors.white10 : Colors.black12),
        ),
        child: Icon(icon, color: fg, size: 22),
      ),
    );
  }

  void _openAccount() {
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
  }

  Widget _buildListPane(Brightness brightness, bool isDark, bool split) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isSearching
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchUser,
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.tertiaryColor,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.tertiaryColor,
                      ),
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
                  Tab(text: 'Sohbetler'),
                  Tab(text: 'Topluluklar'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ScrollFog(
                      scrollController: _scrollController,
                      color: AppColors.background,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          _buildRecentChatsSliver(brightness, isDark, split),
                          if (_peopleWithoutChats.isNotEmpty)
                            const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final people = _peopleWithoutChats;
                                if (index == people.length) {
                                  return _isLoadingUsers
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }
                                final user = people[index];
                                return _buildUserTile(
                                  user,
                                  brightness,
                                  isDark,
                                  split: split,
                                );
                              },
                              childCount: _peopleWithoutChats.length +
                                  (_hasMoreUsers || _isLoadingUsers ? 1 : 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCommunitiesTab(brightness, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatPane() {
    final open = _openChat;
    if (open == null) {
      return ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThemeAvatar(
                name: 'Edge',
                radius: 36,
                icon: Icons.chat_bubble_outline_rounded,
              ),
              const SizedBox(height: 16),
              Text(
                'Bir sohbet seç',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.edgeTitleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Soldan bir kişiye tıklayınca sohbet burada açılır.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ChatDetailScreen(
      key: ValueKey(open.key),
      title: open.title,
      receiverId: open.receiverId,
      chatId: open.chatId,
      isGroup: open.isGroup,
      canDeleteGroup: open.isGroup && _canDeleteGroups,
      embedded: true,
      onClose: () => setState(() => _openChat = null),
    );
  }

  void _openConversation({
    required String title,
    String? receiverId,
    String? chatId,
    bool isGroup = false,
    required bool split,
  }) {
    if (isGroup && !_canOpenGroups) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu grubu yalnızca Yönetici ve Mod açabilir.'),
        ),
      );
      return;
    }
    if (!isGroup && (receiverId == null || receiverId.isEmpty)) return;

    final open = _OpenChat(
      title: title,
      receiverId: receiverId,
      chatId: chatId,
      isGroup: isGroup,
    );

    if (split) {
      setState(() => _openChat = open);
      return;
    }

    Navigator.push(
      context,
      SlideRightRoute(
        page: ChatDetailScreen(
          title: title,
          receiverId: isGroup ? null : receiverId,
          chatId: isGroup ? chatId : null,
          isGroup: isGroup,
          canDeleteGroup: isGroup && _canDeleteGroups,
        ),
      ),
    );
  }

  Widget _buildCommunitiesTab(Brightness brightness, bool isDark) {
    return Column(
      children: [
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
                      leading: ThemeAvatar(
                        name: comm['name'] ?? 'T',
                        radius: 20,
                        icon: Icons.groups_rounded,
                      ),
                      title: Text(comm['name'] ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      subtitle: Text(comm['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.tertiaryColor)),
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideRightRoute(
                            page: CommunityDetailScreen(
                              community: comm,
                              userRole: widget.userRole,
                              userEmail: widget.userEmail,
                            ),
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

  List<Map<String, dynamic>> get _peopleWithoutChats {
    final chatIds = _recentChats
        .map((chat) => (chat['otherUserId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    return _suggestedUsers.where((user) {
      final id = (user['uid'] ?? user['userId'] ?? user['id'] ?? '').toString();
      return id.isEmpty || !chatIds.contains(id);
    }).toList();
  }

  Widget _buildRecentChatsSliver(
    Brightness brightness,
    bool isDark,
    bool split,
  ) {
    final chats = _recentChats;
    if (chats.isEmpty) {
      if (_suggestedUsers.isEmpty && !_isLoadingUsers) {
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
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chat = chats[index];
          if (chat['isGroup'] == true) {
            return _buildUserTile({
              'uid': '',
              'chatId': chat['chatId'],
              'name': chat['groupName'],
              'isGroup': true,
              'preview': _chatPreview(chat),
            }, brightness, isDark, split: split);
          }

          final otherId = (chat['otherUserId'] ?? '').toString();
          if (otherId.isEmpty) return const SizedBox.shrink();

          return FutureBuilder<Map<String, dynamic>>(
            future: _profileForChatPartner(otherId),
            builder: (context, userSnapshot) {
              final userData = Map<String, dynamic>.from(
                userSnapshot.data ??
                    {
                      'uid': otherId,
                      'userId': otherId,
                      'id': otherId,
                      'name': otherId,
                    },
              );
              userData['uid'] = otherId;
              userData['userId'] ??= otherId;
              userData['id'] ??= otherId;
              userData['chatId'] = chat['chatId'];
              userData['preview'] = _chatPreview(chat);
              return _buildUserTile(
                userData,
                brightness,
                isDark,
                split: split,
              );
            },
          );
        },
        childCount: chats.length,
      ),
    );
  }

  String _chatPreview(Map<String, dynamic> chat) {
    final mine = chat['lastSenderId'] == AuthService().currentUser?.uid;
    final type = (chat['lastMessageType'] as String?) ?? 'text';
    if (mine) {
      return type == 'text' ? 'Mesaj gönderdin' : 'Dosya gönderdin';
    }
    return type == 'text' ? 'Sana bir mesaj gönderildi' : 'Sana bir dosya gönderildi';
  }

  Future<Map<String, dynamic>> _profileForChatPartner(String userId) async {
    final cached = _partnerCache[userId];
    if (cached != null) return cached;
    final profile = await _chatService.resolvePublicProfile(userId);
    _partnerCache[userId] = profile;
    return profile;
  }

  Widget _buildUserTile(
    Map<String, dynamic> user,
    Brightness brightness,
    bool isDark, {
    required bool split,
  }) {
    final isOnline = user['isOnline'] == true;
    final isGroup = user['isGroup'] == true;
    final chatId = user['chatId'];

    String displayName = (user['name'] ?? '').toString().trim();
    if (displayName.isEmpty) {
      displayName = isGroup
          ? 'İsimsiz Grup'
          : (user['username'] ??
                  user['email'] ??
                  AppLocalizations.of(context)!.anonymousUser)
              .toString()
              .trim();
    }

    final uid = (user['uid'] ?? user['userId'] ?? user['id'] ?? '').toString();
    final tileKey = isGroup ? 'g:${chatId ?? ''}' : 'u:$uid';
    final selected = _openChat?.key == tileKey;

    return Material(
      color: selected
          ? AppColors.senaryColor.withValues(alpha: AppColors.isDarkUi ? 0.18 : 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          _openConversation(
            title: displayName,
            receiverId: isGroup ? null : uid,
            chatId: isGroup ? chatId?.toString() : null,
            isGroup: isGroup,
            split: split,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ThemeAvatar(
                name: displayName,
                radius: 22,
                isOnline: isOnline,
                icon: isGroup ? Icons.groups_rounded : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if ((user['preview'] ?? '').toString().isNotEmpty)
                      Text(
                        user['preview'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.senaryColor,
                          fontSize: 12,
                        ),
                      )
                    else if (user['username'] != null)
                      Text(
                        '@${user['username']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.tertiaryColor,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (isGroup && _canDeleteGroups)
                IconButton(
                  tooltip: 'Grubu sil',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.septenaryColor,
                  ),
                  onPressed: () {
                    final id = chatId?.toString() ?? '';
                    if (id.isEmpty) return;
                    _confirmDeleteGroupFromList(id, displayName);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenChat {
  final String title;
  final String? receiverId;
  final String? chatId;
  final bool isGroup;

  const _OpenChat({
    required this.title,
    this.receiverId,
    this.chatId,
    this.isGroup = false,
  });

  String get key => isGroup ? 'g:${chatId ?? ''}' : 'u:${receiverId ?? ''}';
}
