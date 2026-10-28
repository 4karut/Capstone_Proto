import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/signup_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ID checks and sign in ignore ID case and surrounding spaces', () {
    final store = DemoAuthStore();
    expect(store.isIdAvailable(' HANTUCK01 '), isFalse);
    expect(
      store.signIn(' HANTUCK01 ', DemoAuthStore.samplePassword)?.id,
      DemoAuthStore.sampleId,
    );
    expect(store.signIn(DemoAuthStore.sampleId, 'incorrect'), isNull);
    expect(store.signIn('unknown', DemoAuthStore.samplePassword), isNull);
  });

  test(
    'new account can log in and duplicate registration cannot overwrite it',
    () {
      final store = DemoAuthStore(seedDemoAccount: false);
      DemoAccount register(String id) => store.register(
        id: id,
        password: 'password123',
        name: '한턱 사용자',
        birthDate: DateTime(2000),
        email: 'person@example.com',
        phoneNumber: '010-1234-5678',
      );
      final account = register('NewUser');
      expect(account.phoneNumber, '01012345678');
      expect(store.signIn('newuser', 'password123'), same(account));
      expect(() => register('NEWUSER'), throwsStateError);
      expect(
        DemoAuthStore(seedDemoAccount: false).isIdAvailable('NewUser'),
        isTrue,
      );
    },
  );

  test('confirmation requires an exact password match', () {
    expect(SignupValidation.passwordConfirmation('', 'password123'), isNotNull);
    expect(
      SignupValidation.passwordConfirmation('Password123', 'password123'),
      isNotNull,
    );
    expect(
      SignupValidation.passwordConfirmation('password123', 'password123'),
      isNull,
    );
  });

  test('phone accepts Korean phone formats and rejects incomplete numbers', () {
    expect(SignupValidation.phone('010-1234-5678'), isNull);
    expect(SignupValidation.phone('01012345678'), isNull);
    expect(SignupValidation.phone('02-123-4567'), isNull);
    expect(SignupValidation.phone(''), isNotNull);
    expect(SignupValidation.phone('123456789'), isNotNull);
    expect(SignupValidation.phone('010abc45678'), isNotNull);
  });
}
