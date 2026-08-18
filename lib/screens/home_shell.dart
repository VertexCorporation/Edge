import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/role.dart';
import '../services/auth.dart';
import '../widgets/background.dart';
import 'tasks.dart';
import 'chat/list.dart' show ChatListScreen;
import 'package:edge/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Authenticated home with bottom navigation: Görevler | Sohbetler
class HomeShell extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userEmail;
  final bool isVertex;

  const HomeShell({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.isVertex,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final role = UserRole.normalize(widget.userRole);
    final canManageTasks = UserRole.canManageTasks(role) ||
        AuthService.isBootstrapAdminEmail(widget.userEmail);
    final themeProvider = context.watch<ThemeProvider>();
    final themeStamp = '${themeProvider.accentTheme}_${themeProvider.darkMode}';

    final tasksTab = TasksScreen(
      key: ValueKey('tasks_$themeStamp'),
      userName: widget.userName,
      userRole: role,
      canManageTasks: canManageTasks,
      isEmbedded: true,
    );
    final chatsTab = ChatListScreen(
      key: ValueKey('chats_$themeStamp'),
      userName: widget.userName,
      userRole: role,
      userEmail: widget.userEmail,
      isVertex: widget.isVertex,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ThemedSkyShell(
        child: kIsWeb
            ? (_index == 0 ? tasksTab : chatsTab)
            : IndexedStack(
                index: _index,
                sizing: StackFit.expand,
                children: [
                  IgnorePointer(
                    ignoring: _index != 0,
                    child: TickerMode(enabled: _index == 0, child: tasksTab),
                  ),
                  IgnorePointer(
                    ignoring: _index != 1,
                    child: TickerMode(enabled: _index == 1, child: chatsTab),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.secondaryColor,
        indicatorColor: AppColors.senaryColor.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt, color: AppColors.senaryColor),
            label: AppLocalizations.of(context)!.tasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.senaryColor),
            label: AppLocalizations.of(context)!.chats,
          ),
        ],
      ),
    );
  }
}
