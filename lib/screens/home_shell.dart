import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    final showTasks = widget.isVertex;
    final tabs = showTasks ? <Widget>[tasksTab, chatsTab] : <Widget>[chatsTab];

    // When tasks tab is hidden, always keep selectedIndex aligned with the
    // remaining tabs list.
    if (!showTasks && _index != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = 0);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ThemedSkyShell(
        child: kIsWeb
            ? tabs[_index]
            : IndexedStack(
                index: _index,
                sizing: StackFit.expand,
                children: tabs
                    .asMap()
                    .entries
                    .map(
                      (e) => IgnorePointer(
                        ignoring: _index != e.key,
                        child: TickerMode(
                          enabled: _index == e.key,
                          child: e.value,
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.secondaryColor,
        indicatorColor: AppColors.senaryColor.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          if (showTasks)
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline, color: AppColors.tertiaryColor),
              selectedIcon: Icon(Icons.check_circle, color: AppColors.senaryColor),
              label: AppLocalizations.of(context)!.tasks,
            ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.tertiaryColor),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.senaryColor),
            label: AppLocalizations.of(context)!.chats,
          ),
        ],
      ),
    );
  }
}
