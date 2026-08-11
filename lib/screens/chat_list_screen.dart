import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _initKeys();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _initKeys() async {
    try {
      await _chatService.initializeKeys();
    } catch (e) {
      debugPrint('Error initializing keys: $e');
    }
    if (mounted) {
      setState(() => _isInitializingKeys = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatService.getUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}'));
                      }

                      final allUsers = snapshot.data ?? [];
                      final users = allUsers.where((u) {
                        final name = (u['name'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'Kullanıcı bulunamadı.',
                            style: GoogleFonts.inter(
                              color: VertexColors.textMuted(brightness),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isOnline = user['isOnline'] == true;
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
                                      user['name']?.substring(0, 1).toUpperCase() ?? '?',
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
                                user['name'] ?? 'İsimsiz Kullanıcı',
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
                                      receiverName: user['name'] ?? 'İsimsiz',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
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
