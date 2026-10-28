abstract final class SignupValidation {
  static String? id(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return '아이디를 입력해 주세요.';
    if (!RegExp(r'^[a-zA-Z0-9]{4,20}$').hasMatch(value)) {
      return '영문과 숫자로 4~20자를 입력해 주세요.';
    }
    return null;
  }

  static String? password(String? input) {
    final value = input ?? '';
    if (value.isEmpty) return '비밀번호를 입력해 주세요.';
    if (value.length < 8 ||
        value.length > 32 ||
        !RegExp(r'[a-zA-Z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value) ||
        RegExp(r'\s').hasMatch(value)) {
      return '공백 없이 영문과 숫자를 포함한 8~32자를 입력해 주세요.';
    }
    return null;
  }

  static String? name(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return '이름을 입력해 주세요.';
    if (value.length > 50) return '이름은 50자 이내로 입력해 주세요.';
    return null;
  }

  static String? passwordConfirmation(String? input, String password) {
    if (input == null || input.isEmpty) return '비밀번호를 한 번 더 입력해 주세요.';
    if (input != password) return '비밀번호가 일치하지 않아요.';
    return null;
  }

  static String? phone(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return '전화번호를 입력해 주세요.';
    if (!RegExp(r'^[0-9-]+$').hasMatch(value) ||
        !RegExp(r'^0\d{8,10}$').hasMatch(value.replaceAll('-', ''))) {
      return '전화번호를 확인해 주세요. 예: 010-1234-5678';
    }
    return null;
  }

  static String? birthDate(String? input, {DateTime? today}) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return '생년월일을 입력해 주세요.';
    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return '생년월일을 숫자 8자리로 입력해 주세요.';
    }
    final year = int.parse(value.substring(0, 4));
    final month = int.parse(value.substring(4, 6));
    final day = int.parse(value.substring(6, 8));
    final date = DateTime(year, month, day);
    final now = today ?? DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);
    if (year < 1900 ||
        date.year != year ||
        date.month != month ||
        date.day != day ||
        date.isAfter(lastDate)) {
      return '실제 생년월일을 확인해 주세요.';
    }
    return null;
  }

  static String? email(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return '이메일을 입력해 주세요.';
    if (value.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return '이메일 주소를 확인해 주세요. 예: hello@example.com';
    }
    return null;
  }
}
