import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/role.dart';
import 'chat/list.dart' show ChatListScreen;
import 'package:provider/provider.dart';

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
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final role = UserRole.normalize(widget.userRole);
    final themeProvider = context.watch<ThemeProvider>();
    final themeStamp = themeProvider.accentTheme + '_' + themeProvider.darkMode.toString();

    return ChatListScreen(
      key: ValueKey('chats_' + themeStamp),
      userName: widget.userName,
      userRole: role,
      userEmail: widget.userEmail,
      isVertex: widget.isVertex,
    );
  }
}
