/// Vertex Edge user roles stored in Firestore as plain strings.
class UserRole {
  UserRole._();

  static const member = 'Üye';
  static const developer = 'Geliştirici';
  static const admin = 'Yönetici';

  static const all = [member, developer, admin];

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
        lower == 'admin' ||
        lower == 'yönetici ') {
      return admin;
    }
    if (lower == 'üye' || lower == 'uye' || lower == 'member') {
      return member;
    }
    return role;
  }

  /// Yönetici can assign tasks to other users.
  static bool canManageTasks(String? role) =>
      normalize(role) == admin;

  /// Yönetici can assign roles from [assignableByAdmin].
  static bool canManageRoles(String? role) => normalize(role) == admin;

  static const assignableByAdmin = [member, developer];

  /// Geliştirici behaves like Üye — no extra permissions.
  static bool isDeveloper(String? role) =>
      normalize(role) == developer;
}
