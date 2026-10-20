import 'package:flutter_test/flutter_test.dart';
import '../lib/services/console_membership.dart';

void main() {
  test('current Core membership works without historic admin claims', () {
    expect(isVerifiedConsoleCore({'isCore': true, 'departments': ['Core']}), isTrue);
    expect(isVerifiedConsoleCore({'isAdmin': true, 'departments': ['Core', 'Aero']}), isTrue);
  });
  test('legacy flags alone, revoked Core and malformed grants fail closed', () {
    for (final data in [null, {}, {'admin': true, 'isAdmin': true},
      {'isCore': false, 'departments': ['Core']},
      {'isCore': true, 'departments': ['Aero']},
      {'isCore': true, 'departments': ['Core', 'Unknown']}]) {
      expect(isVerifiedConsoleCore(data), isFalse);
    }
  });
}
