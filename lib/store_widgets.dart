import 'package:flutter/material.dart';

import 'group_widgets.dart';
import 'store_catalog.dart';
import 'theme.dart';

class StoreListCard extends StatelessWidget {
  const StoreListCard({
    required this.store,
    required this.onTap,
    required this.available,
    this.favorite = false,
    super.key,
  });
  final DemoStore store;
  final VoidCallback onTap;
  final bool available;
  final bool favorite;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: HantuckColors.border),
      ),
      child: InkWell(
        key: ValueKey('store-card-${store.id}'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              store.thumbnail,
              height: 150,
              fit: BoxFit.cover,
              semanticLabel: '${store.name} 썸네일',
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (favorite)
                        const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFE54958),
                          size: 18,
                        ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: HantuckColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    store.description,
                    style: const TextStyle(fontSize: 12, height: 1.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    store.address,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.6,
                      color: HantuckColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GroupTags(tags: store.tags),
                  const SizedBox(height: 14),
                  Text(
                    available ? '그룹 선결제 이용 가능' : '현재 이용 가능한 선결제가 없어요',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: available
                          ? HantuckColors.orange
                          : HantuckColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DiscoveryEmptyState extends StatelessWidget {
  const DiscoveryEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFBF9),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HantuckColors.border),
    ),
    child: Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: HantuckColors.orangeSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: HantuckColors.orange, size: 32),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.8,
            color: HantuckColors.muted,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}
