/// Reads Cortex-registered people from the shared `users/{uid}` docs.
/// Cortex owns `username`, subscription, and credits — Edge only maps them.
class CortexProfile {
  CortexProfile._();

  static bool isAnonymousAccount(Map<String, dynamic>? data) {
    return data?['accountType']?.toString() == 'anonymous';
  }

  /// Edge people lists should not dump Cortex-only accounts.
  /// Anyone who logged into Edge or has chat keys still belongs in the list.
  static bool isEdgeListed(Map<String, dynamic>? data) {
    if (data == null || isAnonymousAccount(data)) return false;
    if (data['isEdge'] == true) return true;
    if (data['publicKey'] != null) return true;
    if (isRegistered(data)) return false;
    return data['lastSeen'] != null;
  }

  /// Cortex writes `username` (and often subscription/accountType) on register.
  static bool isRegistered(Map<String, dynamic>? data) {
    if (data == null || isAnonymousAccount(data)) return false;
    final username = (data['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return true;
    if (data.containsKey('hasCortexSubscription')) return true;
    final accountType = data['accountType']?.toString().trim();
    return accountType != null && accountType.isNotEmpty;
  }

  static String? usernameOf(Map<String, dynamic>? data) {
    final username = (data?['username'] as String?)?.trim();
    if (username == null || username.isEmpty) return null;
    return username;
  }

  /// Edge UI uses `name`; Cortex stores the public handle as `username`.
  static String displayName(
    Map<String, dynamic>? data, {
    String? fallback,
  }) {
    final name = (data?['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final username = usernameOf(data);
    if (username != null) return username;
    final email = (data?['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) return email;
    final fb = fallback?.trim();
    if (fb != null && fb.isNotEmpty) return fb;
    return 'Kullanıcı';
  }

  static bool isVertexMember(Map<String, dynamic>? data) {
    if (data?['isVertex'] == true) return true;
    return isRegistered(data);
  }
}
