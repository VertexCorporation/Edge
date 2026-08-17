import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/role.dart';
import '../services/auth.dart';
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

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TasksScreen(
            userName: widget.userName,
            userRole: role,
            canManageTasks: canManageTasks,
            isEmbedded: true,
          ),
          ChatListScreen(
            userName: widget.userName,
            userRole: role,
            userEmail: widget.userEmail,
            isVertex: widget.isVertex,
          ),
        ],
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
