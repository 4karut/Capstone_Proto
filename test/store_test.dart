import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_proto/src/store.dart';

void main() {
  late AppStore s;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = AppStore();
    await s.load();
    s.loginDemo(merchant: true);
  });
  test(
    'shop request does not debit; approval splits extra and rejects duplicate',
    () {
      final b = s.benefit('b1'), original = s.benefit('b1').remaining;
      final r = s.issue(b);
      s.submitOrder(r, '따뜻한 제육 덮밥', 8000);
      expect(b.remaining, original);
      final u = s.approve(r);
      expect(u.applied, 5000);
      expect(u.extra, 3000);
      expect(b.remaining, original - 5000);
      expect(s.allowance(b), 0);
      expect(() => s.approve(r), throwsStateError);
      expect(s.usages.length, 1);
    },
  );
  test('unverified community, expired QR, revoked benefit and cancelled requests are blocked', () {
    expect(() => s.issue(s.benefit('b4')), throwsStateError);
    final b = s.benefit('b1'), r = s.issue(s.benefit('b1'));
    r.expiresAt = DateTime.now().subtract(const Duration(seconds: 1));
    expect(() => s.submitOrder(r, '따뜻한 제육 덮밥', 8000), throwsStateError);
    final fresh = s.issue(b);
    s.submitOrder(fresh, '따뜻한 제육 덮밥', 8000);
    s.cancelRequest(fresh);
    expect(() => s.approve(fresh), throwsStateError);
    expect(b.remaining, 145000);
    final other = s.issue(b);
    s.submitOrder(other, '따뜻한 제육 덮밥', 8000);
    b.status = 'refund';
    expect(() => s.approve(other), throwsStateError);
  });
  test('menu restrictions, merchant permissions and remaining shared balance are respected', () {
    final b = s.benefit('b2'), r = s.issue(s.benefit('b2'));
    expect(() => s.submitOrder(r, '딸기 크림 케이크', 6000), throwsStateError);
    s.merchantAccess = false;
    expect(() => s.submitOrder(r, '아메리카노', 4500), throwsStateError);
    s.merchantAccess = true;
    b.remaining = 1500;
    s.submitOrder(r, '아메리카노', 4500);
    final u = s.approve(r);
    expect(u.applied, 1500);
    expect(u.extra, 3000);
    expect(b.state, 'exhausted');
  });
  test('refund freezes usage and completes without consuming used funds', () {
    final b = s.benefit('b3');
    final t = s.submitTicket(b.id, '취소·환불', '남은 금액을 환불하고 싶어요', '영수증 번호 123');
    expect(b.state, 'refund');
    expect(s.allowance(b), 0);
    s.advanceTicket(t);
    expect(t.status, '검토 중');
    s.advanceTicket(t);
    expect(t.status, '처리 완료');
    expect(b.state, 'cancelled');
    expect(b.remaining, 35000);
    expect(
      () => s.submitTicket('b1', '취소·환불', '타인 결제 취소 요청', ''),
      throwsStateError,
    );
  });
  test('successful payment and edited data survive app reload; pending QR does not', () async {
    final b = s.pay(
      shopId: 's1',
      target: 'school',
      amount: 30000,
      limit: 4000,
      expiry: DateTime.now().add(const Duration(days: 10)),
      donor: '익명',
      message: '힘내세요',
      menus: [],
    );
    final r = s.issue(b);
    s.submitOrder(r, '따뜻한 제육 덮밥', 8000);
    final u = s.approve(r);
    s.settled.add(u.id);
    s.nickname = '새 이웃';
    s.commit();
    await s.flush();
    final restored = AppStore();
    await restored.load();
    expect(restored.benefit(b.id).remaining, 26000);
    expect(restored.usages.single.extra, 4000);
    expect(restored.nickname, '새 이웃');
    expect(restored.settled, contains(u.id));
    expect(restored.request, isNull);
  });
}
