import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:async';
import '../theme/colors.dart';
import '../widgets/background.dart';
import '../widgets/text.dart';
import '../widgets/edge_drawer.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

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

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isInitializingKeys = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  final ScrollController _scrollController = ScrollController();
  
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
    if (mounted) {
      setState(() => _isInitializingKeys = false);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: EdgeDrawer(
        userName: widget.userName,
        userRole: widget.userRole,
        userEmail: widget.userEmail,
        isVertex: widget.isVertex,
      ),
      body: GeoBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: CircleAvatar(
                        backgroundColor: VertexColors.primary(brightness).withValues(alpha: 0.2),
                        child: Text(
                          widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            color: VertexColors.primary(brightness),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GradientText(
                      'Edge',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: FaIcon(
                        _isSearching ? FontAwesomeIcons.xmark : FontAwesomeIcons.magnifyingGlass,
                      ),
                      color: isDark ? Colors.white : Colors.black,
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Search Bar
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
                            hintText: 'Kullanıcı Ara...',
                            hintStyle: TextStyle(color: VertexColors.textMuted(brightness)),
                            prefixIcon: Icon(Icons.search, color: VertexColors.textMuted(brightness)),
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

              if (_isInitializingKeys)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: VertexColors.primary(brightness)),
                  ),
                )
              else
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Recent Chats Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Text(
                            'Sohbetler',
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
                                    color: VertexColors.primary(brightness).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: FaIcon(
                                    FontAwesomeIcons.userPlus,
                                    size: 16,
                                    color: VertexColors.primary(brightness),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Kişiler Öner',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: VertexColors.primary(brightness),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _showSuggestions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: VertexColors.primary(brightness),
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
                                return _isLoadingUsers
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(child: CircularProgressIndicator()),
                                      )
                                    : const SizedBox.shrink();
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChatsStream(Brightness brightness, bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getRecentChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Text(
                'Henüz kimseyle konuşmadınız, hemen sohbete başlayın.',
                style: GoogleFonts.inter(
                  color: VertexColors.textMuted(brightness),
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
    String displayName = (user['name'] ?? '').toString().trim();
    if (displayName.isEmpty) {
      displayName = (user['username'] ?? user['email'] ?? 'İsimsiz Kullanıcı').toString().trim();
    }
    
    // Some endpoints may return 'uid' or 'userId' or 'id'
    final uid = user['uid'] ?? user['userId'] ?? user['id'] ?? '';

    return Card(
      color: VertexColors.glassBg(brightness),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: VertexColors.glassBorder(brightness)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: VertexColors.primary(brightness).withValues(alpha: 0.2),
              child: Text(
                displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?',
                style: GoogleFonts.inter(
                  color: VertexColors.primary(brightness),
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
                      color: VertexColors.bgCard(brightness),
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
                  color: VertexColors.textMuted(brightness),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: FaIcon(
          FontAwesomeIcons.chevronRight,
          color: VertexColors.textMuted(brightness),
          size: 16,
        ),
        onTap: () {
          if (uid.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                receiverId: uid,
                receiverName: displayName,
              ),
            ),
          );
        },
      ),
    );
  }
}
