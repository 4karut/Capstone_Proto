import 'group_store.dart';
import 'donation_store.dart';
import 'store_catalog.dart';
import 'prepaid_usage_store.dart';
import 'thanks_photo_picker.dart' as photos;

class DemoAccount {
  const DemoAccount({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.email,
    required this.phoneNumber,
  });

  final String id;
  final String name;
  final DateTime birthDate;
  final String email;
  final String phoneNumber;
}

class _DemoCredential {
  const _DemoCredential(this.account, this.password);
  final DemoAccount account;
  final String password;
}

/// Local, temporary credentials for UI review only. Nothing is persisted.
class DemoAuthStore {
  DemoAuthStore({
    bool seedDemoAccount = true,
    DemoGroupStore? groupStore,
    Future<UsagePhoto?> Function()? thanksPhotoPicker,
  }) : groups = groupStore ?? DemoGroupStore() {
    stores = DemoStoreCatalog(
      canApprove: isAdmin,
      now: () => groups.currentTime,
    );
    donations = DemoDonationStore(groups: groups, stores: stores);
    usage = DemoPrepaidUsageStore(groups: groups, stores: stores);
    pickThanksPhoto = thanksPhotoPicker ?? photos.pickThanksPhoto;
    if (seedDemoAccount) {
      register(
        id: sampleId,
        password: samplePassword,
        name: '한나눔',
        birthDate: DateTime(2001, 3, 15),
        email: 'demo@hantuck.example',
        phoneNumber: '01000000000',
      );
      for (var index = 1; index <= 3; index++) {
        register(
          id: 'leader0$index',
          password: samplePassword,
          name: '예시 그룹 $index 그룹장',
          birthDate: DateTime(1990, 1, index),
          email: 'leader0$index@hantuck.example',
          phoneNumber: '0100000000$index',
        );
      }
      register(
        id: 'store01',
        password: samplePassword,
        name: '예시 가게 1 사장님',
        birthDate: DateTime(1985, 1, 1),
        email: 'store01@hantuck.example',
        phoneNumber: '01000000004',
      );
      register(
        id: 'admin01',
        password: samplePassword,
        name: '한턱 관리자',
        birthDate: DateTime(1990, 1, 1),
        email: 'admin@hantuck.example',
        phoneNumber: '01000000005',
      );
      _admins.add(_key('admin01'));
    }
  }

  static const sampleId = 'hantuck01';
  static const samplePassword = 'welcome123!';
  final Map<String, _DemoCredential> _accounts = {};
  final DemoGroupStore groups;
  late final DemoStoreCatalog stores;
  late final DemoDonationStore donations;
  late final DemoPrepaidUsageStore usage;
  late final Future<UsagePhoto?> Function() pickThanksPhoto;
  final Set<String> _admins = {};
  bool isAdmin(String userId) => _admins.contains(_key(userId));

  static String _key(String id) => id.trim().toLowerCase();

  bool isIdAvailable(String id) => !_accounts.containsKey(_key(id));

  DemoAccount register({
    required String id,
    required String password,
    required String name,
    required DateTime birthDate,
    required String email,
    required String phoneNumber,
  }) {
    if (!isIdAvailable(id)) {
      throw StateError('이미 사용 중인 아이디예요.');
    }
    final account = DemoAccount(
      id: id.trim(),
      name: name.trim(),
      birthDate: birthDate,
      email: email.trim(),
      phoneNumber: phoneNumber.replaceAll(RegExp(r'\D'), ''),
    );
    _accounts[_key(id)] = _DemoCredential(account, password);
    return account;
  }

  DemoAccount? signIn(String id, String password) {
    final record = _accounts[_key(id)];
    return record != null && record.password == password
        ? record.account
        : null;
  }
}
