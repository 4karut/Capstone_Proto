import 'dart:math';

String won(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}원';
String dateLabel(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
String shortDate(DateTime d) => '${d.month}.${d.day}';

class Community {
  final String id, name, description, emailDomain, code;
  const Community(
    this.id,
    this.name,
    this.description,
    this.emailDomain,
    this.code,
  );
}

const communities = [
  Community(
    'school',
    '한마음대학교',
    '배움과 응원이 모이는 우리 학교',
    'hanmaeum.ac.kr',
    'CAMPUS2026',
  ),
  Community('volunteer', '온기 봉사단', '작은 실천으로 따뜻한 동네를 만드는 사람들', '', 'WARM2026'),
  Community('village', '성북 청년마을', '서로의 일상을 응원하는 동네 공동체', '', 'YOUTH2026'),
];

class MenuItem {
  final String name;
  final int price;
  const MenuItem(this.name, this.price);
  Map<String, dynamic> toJson() => {'name': name, 'price': price};
  factory MenuItem.fromJson(Map<String, dynamic> j) =>
      MenuItem(j['name'], j['price']);
}

class Shop {
  final String id, name, category, emoji, address, distance;
  String description, hours;
  List<MenuItem> menu;
  final int color;
  Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.address,
    required this.distance,
    required this.description,
    required this.hours,
    required this.menu,
    required this.color,
  });
}

List<Shop> seedShops() => [
  Shop(
    id: 's1',
    name: '온기 식탁',
    category: '한식',
    emoji: '🍚',
    address: '서울 성북구 보문로 34길 12',
    distance: '도보 3분',
    description: '갓 지은 밥 한 그릇에 정성을 담습니다.\n든든한 하루의 시작을 온기 식탁과 함께하세요.',
    hours: '매일 11:00 – 20:30 · 일요일 휴무',
    menu: const [
      MenuItem('따뜻한 제육 덮밥', 8000),
      MenuItem('정성 가득 비빔밥', 7000),
      MenuItem('오늘의 김치찌개', 8500),
    ],
    color: 0xFFF2DEBC,
  ),
  Shop(
    id: 's2',
    name: '모퉁이 커피',
    category: '카페',
    emoji: '☕',
    address: '서울 성북구 동소문로 22길 8',
    distance: '도보 5분',
    description: '잠깐의 쉼이 필요한 날,\n향긋한 커피와 작은 응원을 건넵니다.',
    hours: '매일 09:00 – 22:00',
    menu: const [
      MenuItem('아메리카노', 4500),
      MenuItem('바닐라 라테', 5500),
      MenuItem('딸기 크림 케이크', 6000),
    ],
    color: 0xFFDCE8DB,
  ),
  Shop(
    id: 's3',
    name: '소소 베이커리',
    category: '베이커리',
    emoji: '🥐',
    address: '서울 성북구 보문로 30길 21',
    distance: '도보 7분',
    description: '매일 아침 구워내는 작은 행복.\n오늘도 고소하고 다정한 빵을 준비했어요.',
    hours: '매일 08:00 – 20:00 · 월요일 휴무',
    menu: const [
      MenuItem('버터 크루아상', 4000),
      MenuItem('소금빵', 3000),
      MenuItem('햄 치즈 샌드위치', 6500),
    ],
    color: 0xFFF6DDCD,
  ),
  Shop(
    id: 's4',
    name: '초록 한 그릇',
    category: '샐러드',
    emoji: '🥗',
    address: '서울 성북구 동소문로 18길 6',
    distance: '도보 9분',
    description: '신선한 재료로 채우는 기분 좋은 한 끼.\n가벼워도 든든하게 드세요.',
    hours: '평일 10:00 – 20:00 · 주말 11:00 – 18:00',
    menu: const [MenuItem('치킨 그린볼', 9000), MenuItem('두부 포케', 8500)],
    color: 0xFFE2EAC8,
  ),
];

class Benefit {
  final String id, shopId, communityId, donor, message;
  final int total, limit;
  int remaining;
  final DateTime createdAt, expiresAt;
  final List<String> menus;
  final bool mine;
  String status;
  Benefit({
    required this.id,
    required this.shopId,
    required this.communityId,
    required this.donor,
    required this.message,
    required this.total,
    required this.remaining,
    required this.limit,
    required this.createdAt,
    required this.expiresAt,
    required this.menus,
    this.mine = false,
    this.status = 'active',
  });
  String get state => status != 'active'
      ? status
      : remaining <= 0
      ? 'exhausted'
      : DateTime.now().isAfter(expiresAt)
      ? 'expired'
      : 'active';
  String get stateLabel => switch (state) {
    'active' => '진행 중',
    'exhausted' => '소진',
    'expired' => '기간 만료',
    'refund' => '환불 검토 중',
    'cancelled' => '취소',
    _ => status,
  };
  Map<String, dynamic> toJson() => {
    'id': id,
    'shopId': shopId,
    'communityId': communityId,
    'donor': donor,
    'message': message,
    'total': total,
    'remaining': remaining,
    'limit': limit,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'menus': menus,
    'mine': mine,
    'status': status,
  };
  factory Benefit.fromJson(Map<String, dynamic> j) => Benefit(
    id: j['id'],
    shopId: j['shopId'],
    communityId: j['communityId'],
    donor: j['donor'],
    message: j['message'],
    total: j['total'],
    remaining: j['remaining'],
    limit: j['limit'],
    createdAt: DateTime.parse(j['createdAt']),
    expiresAt: DateTime.parse(j['expiresAt']),
    menus: List<String>.from(j['menus']),
    mine: j['mine'],
    status: j['status'],
  );
}

class Usage {
  final String id, requestId, benefitId, shopId, menu;
  final int orderAmount, applied;
  final DateTime date;
  Usage({
    required this.id,
    required this.requestId,
    required this.benefitId,
    required this.shopId,
    required this.menu,
    required this.orderAmount,
    required this.applied,
    required this.date,
  });
  int get extra => orderAmount - applied;
  Map<String, dynamic> toJson() => {
    'id': id,
    'requestId': requestId,
    'benefitId': benefitId,
    'shopId': shopId,
    'menu': menu,
    'orderAmount': orderAmount,
    'applied': applied,
    'date': date.toIso8601String(),
  };
  factory Usage.fromJson(Map<String, dynamic> j) => Usage(
    id: j['id'],
    requestId: j['requestId'],
    benefitId: j['benefitId'],
    shopId: j['shopId'],
    menu: j['menu'],
    orderAmount: j['orderAmount'],
    applied: j['applied'],
    date: DateTime.parse(j['date']),
  );
}

class UseRequest {
  final String id, benefitId;
  DateTime expiresAt;
  String status = 'issued', menu = '';
  int orderAmount = 0;
  UseRequest(this.id, this.benefitId)
    : expiresAt = DateTime.now().add(const Duration(minutes: 3));
  bool get expired => DateTime.now().isAfter(expiresAt);
  int get seconds => max(0, expiresAt.difference(DateTime.now()).inSeconds);
}

class SupportTicket {
  final String id, targetId, type, reason, evidence;
  final DateTime date;
  String status;
  SupportTicket({
    required this.id,
    required this.targetId,
    required this.type,
    required this.reason,
    required this.date,
    this.evidence = '',
    this.status = '접수',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'targetId': targetId,
    'type': type,
    'reason': reason,
    'date': date.toIso8601String(),
    'evidence': evidence,
    'status': status,
  };
  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
    id: j['id'],
    targetId: j['targetId'],
    type: j['type'],
    reason: j['reason'],
    date: DateTime.parse(j['date']),
    evidence: j['evidence'] ?? '',
    status: j['status'],
  );
}

class AppNotice {
  final String title, body, targetId;
  final DateTime date;
  bool read;
  AppNotice(
    this.title,
    this.body,
    this.targetId,
    this.date, {
    this.read = false,
  });
  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'targetId': targetId,
    'date': date.toIso8601String(),
    'read': read,
  };
  factory AppNotice.fromJson(Map<String, dynamic> j) => AppNotice(
    j['title'],
    j['body'],
    j['targetId'],
    DateTime.parse(j['date']),
    read: j['read'],
  );
}
