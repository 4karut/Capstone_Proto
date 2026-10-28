import 'package:capstone_proto_02/signup_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ID boundaries and permitted alphabet are checked', () {
    expect(SignupValidation.id(' ab12 '), isNull);
    expect(SignupValidation.id('abc'), isNotNull);
    expect(SignupValidation.id('a' * 21), isNotNull);
    expect(SignupValidation.id('한턱01'), isNotNull);
    expect(SignupValidation.id('ab 12'), isNotNull);
  });

  test('password requires letters and digits with no whitespace', () {
    expect(SignupValidation.password('welcome123!'), isNull);
    expect(SignupValidation.password('12345678'), isNotNull);
    expect(SignupValidation.password('abcdefgh'), isNotNull);
    expect(SignupValidation.password('ab123'), isNotNull);
    expect(SignupValidation.password('welcome 123'), isNotNull);
    expect(SignupValidation.password('${'a' * 32}1'), isNotNull);
  });

  test('birth date validates leap years, impossible and future dates', () {
    final today = DateTime(2026, 10, 28);
    String? validate(String value) =>
        SignupValidation.birthDate(value, today: today);
    expect(validate('20000229'), isNull);
    expect(validate('20010229'), isNotNull);
    expect(validate('20001301'), isNotNull);
    expect(validate('20010010'), isNotNull);
    expect(validate('20010100'), isNotNull);
    expect(validate('20261028'), isNull);
    expect(validate('20261029'), isNotNull);
    expect(validate('18991231'), isNotNull);
    expect(validate('2001011'), isNotNull);
  });

  test('email detects malformed inputs and trims outer spaces', () {
    expect(SignupValidation.email(' hello+tag@example.com '), isNull);
    expect(SignupValidation.email('helloexample.com'), isNotNull);
    expect(SignupValidation.email('hello@@example.com'), isNotNull);
    expect(SignupValidation.email('hello@exam ple.com'), isNotNull);
  });

  test('name permits Korean and non Korean names but cannot be blank', () {
    expect(SignupValidation.name('한나눔'), isNull);
    expect(SignupValidation.name('Alex Kim'), isNull);
    expect(SignupValidation.name('   '), isNotNull);
    expect(SignupValidation.name('가' * 51), isNotNull);
  });
}
