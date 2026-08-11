import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/card.dart';
import '../widgets/button.dart';
import '../widgets/text.dart';
import '../services/auth.dart';
import '../main.dart' show themeNotifier;
import '../screens/tasks.dart';

class EdgeDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final String userEmail;
  final bool isVertex;

  const EdgeDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.isVertex,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Drawer(
      backgroundColor: VertexColors.bg(brightness),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              GradientText(
                'Hesap',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // Profile Info
              _buildProfileCard(brightness, isDark),
              const SizedBox(height: 20),

              // Theme Settings
              _buildThemeSection(brightness, isDark),
              const SizedBox(height: 20),

              // Tasks (Only if Vertex)
              if (isVertex) ...[
                const Divider(),
                const SizedBox(height: 12),
                GradientText(
                  'Görevler',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 400, // Compact height for embedded Tasks
                  child: TasksScreen(
                    userName: userName,
                    userRole: userRole,
                    isEmbedded: true,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Divider(),
              const SizedBox(height: 20),

              // Logout button
              VertexButton.outline(
                label: 'Çıkış Yap',
                icon: Icons.logout_rounded,
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).pop();
                  AuthService().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Brightness brightness, bool isDark) {
    return VertexCard(
      animatedBorder: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: VertexColors.primary(brightness).withValues(alpha: 0.2),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: VertexColors.primary(brightness),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userEmail,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: VertexColors.textMuted(brightness),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(Brightness brightness, bool isDark) {
    return VertexCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SwitchListTile(
        title: Text(
          'Karanlık Tema',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        value: isDark,
        activeColor: VertexColors.primary(brightness),
        onChanged: (val) {
          themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
        },
      ),
    );
  }
}
