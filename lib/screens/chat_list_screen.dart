import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../theme/colors.dart';
import '../widgets/background.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  bool _isInitializingKeys = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

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
    } catch (e) {
      debugPrint('Error initializing keys: $e');
    }
    if (mounted) {
      setState(() => _isInitializingKeys = false);
      _fetchUsers();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchUsers();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
          _users.clear();
          _lastDocument = null;
          _hasMore = true;
        });
        _fetchUsers();
      }
    });
  }

  Future<void> _fetchUsers() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final result = await _chatService.getUsersPaginated(
        lastDocument: _lastDocument,
        limit: 20,
        searchQuery: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _users.addAll(result['users'] as List<Map<String, dynamic>>);
          _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          _hasMore = result['hasMore'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
      body: GeoBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kullanıcılar',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? VertexColors.textMainDark : VertexColors.textMainLight,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search),
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
                              borderRadius: BorderRadius.circular(12),
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
                  child: _users.isEmpty && _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _users.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty ? 'Henüz kullanıcı yok.' : 'Kullanıcı bulunamadı.',
                                style: GoogleFonts.inter(
                                  color: VertexColors.textMuted(brightness),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _users.length + (_hasMore ? 1 : 0),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                if (index == _users.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                final user = _users[index];
                                final isOnline = user['isOnline'] == true;
                                
                                String displayName = (user['name'] ?? '').toString().trim();
                                if (displayName.isEmpty) {
                                  displayName = (user['username'] ?? user['email'] ?? 'İsimsiz Kullanıcı').toString().trim();
                                }

                                return Card(
                                  color: VertexColors.glassBg(brightness),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: VertexColors.glassBorder(brightness)),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
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
                                    subtitle: Text(
                                      user['role'] ?? 'Üye',
                                      style: GoogleFonts.inter(
                                        color: VertexColors.textMuted(brightness),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: VertexColors.textMuted(brightness),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatDetailScreen(
                                            receiverId: user['id'],
                                            receiverName: displayName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
