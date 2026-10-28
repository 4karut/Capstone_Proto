import 'server_gateway.dart';
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
    this.gateway,
    DemoGroupStore? groupStore,
    Future<UsagePhoto?> Function()? thanksPhotoPicker,
  }) : groups =
           groupStore ??
           DemoGroupStore(
             now: gateway == null ? null : () => gateway.currentTime,
           ) {
    stores = DemoStoreCatalog(
      canApprove: isAdmin,
      now: () => groups.currentTime,
    );
    donations = DemoDonationStore(groups: groups, stores: stores);
    usage = DemoPrepaidUsageStore(groups: groups, stores: stores);
    groups.gateway = gateway;
    stores.gateway = gateway;
    donations.gateway = gateway;
    usage.gateway = gateway;
    gateway?.applySnapshot = (s) {
      groups.importSnapshot(s);
      stores.importSnapshot(s);
      donations.importSnapshot(s);
      usage.importSnapshot(s);
    };
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

  final ServerGateway? gateway;
  final Map<String, bool> _availability = {};
  String? _emailChallenge, _emailProof;
  DemoAccount? get serverAccount =>
      gateway?.account == null ? null : _account(gateway!.account!);
  static DemoAccount _account(Map<String, dynamic> a) => DemoAccount(
    id: a['id'],
    name: a['name'],
    birthDate: DateTime.parse(a['birthDate']),
    email: a['email'],
    phoneNumber: a['phoneNumber'],
  );
  Future<void> initializeRemote() async {
    await gateway?.initialize();
  }

  Future<DemoAccount?> signInRemote(String id, String password) async {
    if (gateway == null) return signIn(id, password);
    final account = await gateway!.login(id, password);
    return account == null ? null : _account(account);
  }

  Future<bool> checkIdRemote(String id) async {
    final result = gateway == null
        ? isIdAvailable(id)
        : await gateway!.available(id);
    _availability[_key(id)] = result;
    return result;
  }

  Future<void> sendEmailRemote(String email) async {
    _emailProof = null;
    if (gateway != null) _emailChallenge = await gateway!.emailChallenge(email);
  }

  Future<bool> verifyEmailRemote(String code) async {
    if (gateway == null) return code == '123456';
    _emailProof = await gateway!.verifyEmail(_emailChallenge!, code);
    return true;
  }

  Future<DemoAccount> registerRemote({
    required String id,
    required String password,
    required String name,
    required DateTime birthDate,
    required String email,
    required String phoneNumber,
  }) async {
    if (gateway == null) {
      return register(
        id: id,
        password: password,
        name: name,
        birthDate: birthDate,
        email: email,
        phoneNumber: phoneNumber,
      );
    }
    final a = await gateway!.register({
      'id': id,
      'password': password,
      'name': name,
      'birthDate':
          '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
      'email': email,
      'phoneNumber': phoneNumber,
      'verificationToken': _emailProof,
    });
    return _account(a);
  }

  Future<void> signOutRemote() async {
    await gateway?.logout();
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
  bool isAdmin(String userId) => gateway == null
      ? _admins.contains(_key(userId))
      : gateway!.isAdmin && _key(userId) == _key(gateway!.account?["id"] ?? "");

  static String _key(String id) => id.trim().toLowerCase();

  bool isIdAvailable(String id) => gateway == null
      ? !_accounts.containsKey(_key(id))
      : (_availability[_key(id)] ?? true);

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
