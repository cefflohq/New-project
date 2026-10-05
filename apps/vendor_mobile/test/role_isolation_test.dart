import 'package:flutter_test/flutter_test.dart';

import 'package:cefflo_vendor_mobile/core/app_state.dart';
import 'package:cefflo_vendor_mobile/core/auth_access.dart';
import 'package:cefflo_vendor_mobile/data/models.dart';

// Phase 0 role isolation (Founder 2026-10-05): an entry only opens a
// business where the account holds that entry's role.
void main() {
  const ownA = Business(id: 'a', name: 'Own Business', role: 'owner');
  const opB = Business(id: 'b', name: 'Donuts Jo', role: 'operator');
  const helpC = Business(id: 'c', name: 'Kek Mama', role: 'helper');
  const all = [ownA, opB, helpC];

  test('Operator Access never opens the Owner business', () {
    final scoped = businessesForAccess(all, AuthAccess.operator);
    expect(scoped.map((b) => b.id), ['b']);
    expect(scoped.first.isOwner, isFalse);
  });

  test('Helper Access only opens Helper businesses', () {
    final scoped = businessesForAccess(all, AuthAccess.helper);
    expect(scoped.map((b) => b.id), ['c']);
    expect(scoped.first.isHelper, isTrue);
  });

  test('Owner of A with no Operator role gets nothing under Operator Access', () {
    expect(businessesForAccess(const [ownA], AuthAccess.operator), isEmpty);
    expect(businessesForAccess(const [ownA], AuthAccess.helper), isEmpty);
  });

  test('Vendor entry keeps every membership (Owner behaviour unchanged)', () {
    expect(businessesForAccess(all, AuthAccess.vendor), all);
  });
}
