/// Accept only an explicit Core department from the current server response.
/// Deprecated admin/isAdmin booleans cannot manufacture membership.
bool isVerifiedConsoleCore(dynamic response) {
  if (response is! Map) return false;
  final departments = response['departments'];
  if (departments is! List || !departments.contains('Core')) return false;
  const allowed = {'Tensor', 'Curia', 'Core', 'Senatus', 'Pulse', 'Chroma',
    'Catalyst', 'Envoy', 'Aero', 'Array'};
  if (departments.any((department) => !allowed.contains(department))) return false;
  if (response.containsKey('isAdmin') && response['isAdmin'] != true) return false;
  if (response.containsKey('isCore')) return response['isCore'] == true;
  return response['isAdmin'] == true;
}
