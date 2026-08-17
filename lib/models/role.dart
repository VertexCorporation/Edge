/// Vertex Edge user roles stored in Firestore as plain strings.
class UserRole {
  UserRole._();

  static const member = 'Üye';
  static const developer = 'Geliştirici';
  static const admin = 'Yönetici';
  static const test = 'Test';
  static const mod = 'Mod';
  static const support = 'Support';

  static const all = [member, developer, admin, test, mod, support];

  /// Normalizes legacy / inconsistent role strings from Firestore.
  static String normalize(String? role) {
    if (role == null || role.trim().isEmpty) return member;
    final lower = role.trim().toLowerCase();
    if (lower == 'geliştirici' ||
        lower == 'gelistirici' ||
        lower == 'developer' ||
        lower == 'dev') {
      return developer;
    }
    if (lower == 'yönetici' ||
        lower == 'yonetici' ||
        lower == 'admin') {
      return admin;
    }
    if (lower == 'üye' || lower == 'uye' || lower == 'member') {
      return member;
    }
    if (lower == 'test') return test;
    if (lower == 'mod' || lower == 'moderator' || lower == 'moderatör') {
      return mod;
    }
    if (lower == 'support' || lower == 'destek') return support;
    return role;
  }

  /// Yönetici can assign tasks to other users.
  static bool canManageTasks(String? role) =>
      normalize(role) == admin;

  /// Yönetici and Mod can assign roles from [assignableByAdmin].
  static bool canManageRoles(String? role) {
    final normalized = normalize(role);
    return normalized == admin || normalized == mod;
  }

  /// Support can see every group chat, not only ones they joined.
  static bool canSeeAllGroups(String? role) =>
      normalize(role) == support;

  /// Yönetici and Mod can open group chats.
  static bool canOpenGroups(String? role) {
    final normalized = normalize(role);
    return normalized == admin || normalized == mod;
  }

  /// Yönetici and Mod can create group chats.
  static bool canCreateGroups(String? role) => canOpenGroups(role);

  /// Only Yönetici can delete group chats.
  static bool canDeleteGroups(String? role) => normalize(role) == admin;

  static bool isMod(String? role) => normalize(role) == mod;

  static const assignableByAdmin = [
    member,
    developer,
    test,
    mod,
    support,
  ];

  /// Geliştirici behaves like Üye — no extra permissions.
  static bool isDeveloper(String? role) =>
      normalize(role) == developer;
}
