import 'dart:math';

import 'package:capstone_proto_02/group_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sample groups have unique codes, separate categories, and one locked group', () {
    expect(DemoGroupStore.allGroups.map((g) => g.code).toSet(), hasLength(3));
    expect(
      DemoGroupStore.allGroups.map((g) => g.category).toSet(),
      hasLength(3),
    );
    expect(
      DemoGroupStore.allGroups.where((g) => g.locked).single.id,
      'group-3',
    );
    expect(DemoGroupStore().memberships('newuser'), isEmpty);
  });

  test('search accepts names, codes, tags and category combinations', () {
    final store = DemoGroupStore(random: Random(7));
    expect(store.search(query: '예시그룹1').single.id, 'group-1');
    expect(store.search(query: 'hg0002').single.id, 'group-2');
    expect(store.search(query: '#산책').single.id, 'group-3');
    expect(
      store.search(query: '예시 직장인', category: '직장·팀').single.id,
      'group-2',
    );
    expect(store.search(query: '직장인', category: '학교·동문'), isEmpty);
    expect(store.search().map((g) => g.id).toSet(), {
      'group-1',
      'group-2',
      'group-3',
    });
    expect(store.search(category: '취미·모임').single.id, 'group-3');
    expect(store.search(query: '123456'), isEmpty);
  });

  test('optional empty introduction creates an owner notification without membership', () {
    final store = DemoGroupStore();
    final application = store.requestJoin(
      groupId: 'group-1',
      userId: 'newuser',
      userName: '새 사용자',
      introduction: '',
    );
    expect(store.joinStatus('group-1', 'newuser'), GroupJoinStatus.pending);
    expect(store.memberships('newuser'), isEmpty);
    expect(store.notificationsForOwner('leader01').single, same(application));
    expect(store.notificationsForOwner('leader02'), isEmpty);
    expect(
      () => store.requestJoin(
        groupId: 'group-1',
        userId: 'NEWUSER',
        userName: '새 사용자',
        introduction: '',
      ),
      throwsStateError,
    );
  });

  test('only the owner can approve and approval grants membership once', () {
    final store = DemoGroupStore();
    final application = store.requestJoin(
      groupId: 'group-2',
      userId: 'user',
      userName: '신청자',
      introduction: '안녕하세요',
    );
    expect(
      () => store.approve(applicationId: application.id, ownerId: 'leader01'),
      throwsStateError,
    );
    expect(store.isMember('group-2', 'user'), isFalse);
    store.approve(applicationId: application.id, ownerId: 'LEADER02');
    expect(store.isMember('group-2', 'USER'), isTrue);
    expect(store.pendingForUser('user'), isEmpty);
    expect(store.notificationsForOwner('leader02'), isEmpty);
    store.approve(applicationId: application.id, ownerId: 'leader02');
    expect(store.memberships('user'), hasLength(1));
  });

  test('100 user perceived characters are accepted and longer introduction is rejected', () {
    final store = DemoGroupStore();
    store.requestJoin(
      groupId: 'group-1',
      userId: 'emojiuser',
      userName: '사용자',
      introduction: '👨‍👩‍👧‍👦' * 100,
    );
    expect(
      () => store.requestJoin(
        groupId: 'group-2',
        userId: 'longuser',
        userName: '사용자',
        introduction: '가' * 101,
      ),
      throwsStateError,
    );
    expect(store.pendingForUser('longuser'), isEmpty);
  });

  test(
    'locked group only accepts its invitation code and joins immediately',
    () {
      final store = DemoGroupStore();
      expect(
        () => store.requestJoin(
          groupId: 'group-3',
          userId: 'user',
          userName: '사용자',
          introduction: '',
        ),
        throwsStateError,
      );
      expect(
        () => store.joinWithInvitation(
          groupId: 'group-3',
          userId: 'user',
          code: 'HG0003',
        ),
        throwsStateError,
      );
      expect(store.isMember('group-3', 'user'), isFalse);
      store.joinWithInvitation(
        groupId: 'group-3',
        userId: 'user',
        code: '123456',
      );
      expect(store.joinStatus('group-3', 'user'), GroupJoinStatus.member);
      expect(store.pendingForUser('user'), isEmpty);
      expect(store.notificationsForOwner('leader03'), isEmpty);
      expect(
        () => store.joinWithInvitation(
          groupId: 'group-3',
          userId: 'user',
          code: '123456',
        ),
        throwsStateError,
      );
    },
  );
}
