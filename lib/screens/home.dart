import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/background.dart';
import 'tasks.dart';
import 'chat_list_screen.dart';
import 'account.dart';

/// Main home screen with bottom navigation bar
/// 3 tabs: İletişim (left) | Görevler (center, default) | Hesap (right)
class HomeScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userEmail,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 1; // Start from center (Görevler)
  late PageController _pageController;
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: GeoBackground(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            const ChatListScreen(),
            TasksScreen(
              userName: widget.userName,
              userRole: widget.userRole,
            ),
            AccountScreen(
              userName: widget.userName,
              userRole: widget.userRole,
              userEmail: widget.userEmail,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(brightness, isDark),
    );
  }

  Widget _buildBottomNav(Brightness brightness, bool isDark) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _navAnimController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: VertexColors.glassBg(brightness),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: VertexColors.glassBorder(brightness),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'İletişim',
                    brightness: brightness,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.task_alt_outlined,
                    activeIcon: Icons.task_alt_rounded,
                    label: 'Görevler',
                    brightness: brightness,
                    isCenter: true,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Hesap',
                    brightness: brightness,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Brightness brightness,
    bool isCenter = false,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = brightness == Brightness.dark;
    final selectedColor =
        isDark ? VertexColors.primaryDark : VertexColors.primaryLight;
    final unselectedColor = VertexColors.textMuted(brightness);

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isCenter ? 24 : 20,
          vertical: 8,
        ),
        decoration: isSelected
            ? BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(30),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: isCenter ? 26 : 22,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
