import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/role.dart';
import '../services/admin.dart';
import '../services/auth.dart';
import '../theme.dart';
import '../widgets/card.dart';
import '../widgets/fog.dart';
import '../widgets/avatar.dart';

/// Yönetici-only panel for assigning Geliştirici / Üye roles.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminService _adminService = AdminService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<AdminUser> _users = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  final Set<String> _busyEmails = {};

  bool get _isDarkUi => AppColors.isDarkUi;

  Color get _primaryText =>
      _isDarkUi ? Colors.white : AppColors.primaryColor.inverted;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _adminService.listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<AdminUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _assignRole(AdminUser user, String role) async {
    if (user.role == UserRole.admin) return;
    if (user.role == role) return;

    final email = user.email.trim().toLowerCase();
    setState(() => _busyEmails.add(email.isEmpty ? user.userId : email));
    try {
      await _adminService.assignRole(
        email: email,
        role: role,
        userId: user.userId,
      );
      if (!mounted) return;
      setState(() {
        final index = _users.indexWhere((u) => u.userId == user.userId);
        if (index != -1) {
          _users[index] = AdminUser(
            userId: user.userId,
            name: user.name,
            email: user.email,
            role: role,
          );
        }
      });
      _showMessage('${user.name} → $role');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_roleError(e), isError: true);
    } finally {
      if (mounted) {
        setState(
          () => _busyEmails.remove(email.isEmpty ? user.userId : email),
        );
      }
    }
  }

  String _roleError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied') || text.contains('PERMISSION_DENIED')) {
      return 'Rol yazılamadı: yetki yok.';
    }
    if (text.contains('not-found') || text.contains('Kullanıcı bulunamadı')) {
      return 'Kullanıcı bulunamadı.';
    }
    if (text.toLowerCase().contains('firebase') ||
        text.toLowerCase().contains('firestart')) {
      return 'Rol yazılamadı. Bağlantıyı kontrol et, sonra tekrar dene.';
    }
    return 'Rol atanamadı: $error';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.septenaryColor : AppColors.senaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: _primaryText,
        elevation: 0,
        title: Text(
          'Yönetici Paneli',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
          onRefresh: _loadUsers,
          color: AppColors.senaryColor,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Text(
                'Kullanıcılara Üye, Geliştirici, Test, Mod veya Support rolü atayabilirsin. Mod da rol verebilir.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.tertiaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'İsim veya e-posta ara',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.quaternaryColor.withValues(alpha: 0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                VertexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kullanıcılar yüklenemedi',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.tertiaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _loadUsers, child: const Text('Tekrar dene')),
                    ],
                  ),
                )
              else if (_filteredUsers.isEmpty)
                VertexCard(
                  child: Text(
                    'Kullanıcı bulunamadı.',
                    style: GoogleFonts.inter(color: AppColors.tertiaryColor),
                  ),
                )
              else
                ..._filteredUsers.map(_buildUserTile),
            ],
          ),
        ),
    );
  }

  Widget _buildUserTile(AdminUser user) {
    final isProtected = AuthService.isBootstrapAdminEmail(user.email);
    final isAdmin = user.role == UserRole.admin || isProtected;
    final isBusy = _busyEmails.contains(
      user.email.trim().isEmpty ? user.userId : user.email.trim().toLowerCase(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VertexCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThemeAvatar(
              name: user.name,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _primaryText,
                    ),
                  ),
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.tertiaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _roleBadge(isProtected ? UserRole.admin : user.role),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isBusy)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isAdmin)
              Text(
                'Kilitli',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.tertiaryColor,
                ),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Rol ata',
                icon: Icon(Icons.admin_panel_settings_outlined, color: AppColors.senaryColor),
                onSelected: (role) => _assignRole(user, role),
                itemBuilder: (context) => UserRole.assignableByAdmin
                    .map(
                      (role) => PopupMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            if (user.role == role)
                              Icon(Icons.check, size: 18, color: AppColors.senaryColor)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(role),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color color;
    switch (UserRole.normalize(role)) {
      case UserRole.admin:
        color = AppColors.premium;
        break;
      case UserRole.mod:
        color = const Color(0xFFE36414);
        break;
      case UserRole.support:
        color = const Color(0xFF00E5FF);
        break;
      case UserRole.test:
        color = const Color(0xFF8D6E63);
        break;
      case UserRole.developer:
        color = AppColors.senaryColor;
        break;
      default:
        color = AppColors.tertiaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        role,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
