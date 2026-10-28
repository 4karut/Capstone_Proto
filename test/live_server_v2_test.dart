import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_proto_02/demo_auth_store.dart';
import 'package:capstone_proto_02/donation_store.dart';
import 'package:capstone_proto_02/prepaid_usage_store.dart';
import 'package:capstone_proto_02/server_gateway.dart';
import 'package:capstone_proto_02/store_catalog.dart';

void main() {
  test(
    'latest Flutter stores complete v2 server workflow and restore sessions',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = null;
      SharedPreferences.setMockInitialValues({});
      DemoAuthStore make() {
        final g = ServerGateway();
        addTearDown(g.dispose);
        return DemoAuthStore(seedDemoAccount: false, gateway: g);
      }

      final user = make(), owner = make(), admin = make(), leader = make();
      await user.initializeRemote();
      final id = 'live${DateTime.now().microsecondsSinceEpoch}';
      expect(await user.checkIdRemote(id), isTrue);
      await user.sendEmailRemote('$id@example.test');
      expect(await user.verifyEmailRemote('123456'), isTrue);
      final account = await user.registerRemote(
        id: id,
        password: 'welcome123!',
        name: '서버 연동 점검',
        birthDate: DateTime(2001, 3, 15),
        email: '$id@example.test',
        phoneNumber: '01012345678',
      );
      expect(account.id, id);
      expect((await user.signInRemote(id, 'welcome123!'))!.id, id);
      await user.groups.joinWithInvitationRemote(
        groupId: 'group-3',
        userId: id,
        code: '123456',
      );
      final application = await user.groups.requestJoinRemote(
        groupId: 'group-1',
        userId: id,
        userName: account.name,
        introduction: '안녕하세요',
      );
      await leader.initializeRemote();
      await leader.signInRemote('leader01', 'welcome123!');
      await leader.groups.approveRemote(
        applicationId: application.id,
        ownerId: 'leader01',
      );
      await user.gateway!.refresh();
      expect(user.groups.isMember('group-1', id), isTrue);
      await user.groups.toggleFavoriteRemote('group-3', id);
      expect(user.groups.isFavorite('group-3', id), isTrue);
      final donation = await user.donations.completeRemote(
        checkoutId: user.donations.beginCheckout(),
        type: DonationType.prepaid,
        groupId: 'group-3',
        donorId: id,
        donorName: account.name,
        amount: 10000,
        storeId: 'example-store-1',
        expiresOn: seoulCalendarDate(DateTime.now())
            .add(const Duration(days: 1)),
      );
      final offer = 'prepaid-${donation.id}';
      final request = await user.usage.beginRemote(
        offerId: offer,
        userId: id,
        userName: account.name,
      );
      expect(
        user.groups.availablePrepaidOffer(offer, id).remainingAmount,
        10000,
      );
      await owner.initializeRemote();
      await owner.signInRemote('store01', 'welcome123!');
      final scanned = await owner.usage.findForStoreRemote(
        code: request.code,
        storeId: request.storeId,
        ownerId: 'store01',
      );
      await owner.usage.requestAmountRemote(
        requestId: scanned.id,
        storeId: scanned.storeId,
        ownerId: 'store01',
        amount: 6000,
      );
      await user.gateway!.refresh();
      expect(request.status, UsageRequestStatus.awaitingUser);
      expect(
        user.groups.availablePrepaidOffer(offer, id).remainingAmount,
        10000,
      );
      final receipt = await user.usage.approveRemote(
        requestId: request.id,
        userId: id,
      );
      expect(receipt.amount, 6000);
      expect(receipt.remainingAmount, 4000);
      expect(
        (await user.usage.approveRemote(requestId: request.id, userId: id)).id,
        receipt.id,
      );
      await user.usage.sendThanksRemote(
        receiptId: receipt.id,
        userId: id,
        message: '감사합니다',
        photo: UsagePhoto(
          name: 'thanks.png',
          bytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        ),
      );
      await owner.gateway!.refresh();
      expect(
        owner.usage
            .notificationsForStoreOwner('store01')
            .firstWhere((r) => r.id == receipt.id)
            .thanks,
        isNull,
      );
      final reversed = await owner.usage.reversePaymentRemote(
        receiptId: receipt.id,
        storeId: request.storeId,
        ownerId: 'store01',
        reason: '연동 테스트 취소',
      );
      expect(reversed.remainingAmount, 10000);
      await user.gateway!.refresh();
      expect(
        user.groups.availablePrepaidOffer(offer, id).remainingAmount,
        10000,
      );
      expect(user.usage.receiptForUser(receipt.id, id).cancelled, isTrue);
      final number = (DateTime.now().microsecondsSinceEpoch % 10000000000)
          .toString()
          .padLeft(10, '0');
      final app = await user.stores.applyRemote(
        ownerId: id,
        ownerName: account.name,
        name: '연동 가게',
        registrationNumber: number,
        address: '서울 테스트 $id',
        category: '한식',
        phoneNumber: '0212345678',
        description: '연동 점검',
      );
      await admin.initializeRemote();
      await admin.signInRemote('admin01', 'welcome123!');
      expect(admin.isAdmin('admin01'), isTrue);
      await admin.stores.rejectRemote(
        applicationId: app.id,
        adminId: 'admin01',
        reason: '정보 수정 필요',
      );
      await user.gateway!.refresh();
      expect(user.stores.application(app.id, id).rejected, isTrue);
      final resubmitted = await user.stores.applyRemote(
        ownerId: id,
        ownerName: account.name,
        name: '수정한 연동 가게',
        registrationNumber: number,
        address: '서울 테스트 $id',
        category: '한식',
        phoneNumber: '0212345678',
        description: '수정 완료',
        resubmissionOf: app.id,
      );
      await admin.gateway!.refresh();
      final store = await admin.stores.approveRemote(
        applicationId: resubmitted.id,
        adminId: 'admin01',
      );
      await user.gateway!.refresh();
      expect(user.stores.ownsStore(store.id, id), isTrue);
      await user.stores.saveMenuRemote(
        storeId: store.id,
        ownerId: id,
        item: const StoreMenuItem(
          name: '밥 한 끼',
          description: '정식',
          price: 9000,
        ),
      );
      expect(user.stores.store(store.id).menu.single.price, 9000);
      await user.stores.toggleFavoriteRemote(store.id, id);
      expect(user.stores.isFavorite(store.id, id), isTrue);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'hantuck.v2.session:${user.gateway!.api.baseUrl}',
        user.gateway!.api.token!,
      );
      final restored = make();
      await restored.initializeRemote();
      expect(restored.serverAccount!.id, id);
      expect(restored.groups.isMember('group-1', id), isTrue);
      expect(restored.stores.isFavorite(store.id, id), isTrue);
      expect(restored.usage.receiptForUser(receipt.id, id).cancelled, isTrue);
      await restored.signOutRemote();
      expect(restored.serverAccount, isNull);
    },
    skip: !const bool.fromEnvironment('LIVE_API_V2'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
