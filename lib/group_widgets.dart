import 'package:flutter/material.dart';

import 'group_store.dart';
import 'theme.dart';

class GroupThumbnail extends StatelessWidget {
  const GroupThumbnail({required this.group, this.size = 70, super.key});
  final DemoGroup group;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.asset(
      group.thumbnail,
      width: size,
      height: size,
      fit: BoxFit.cover,
      semanticLabel: '${group.name} 썸네일',
    ),
  );
}

class GroupTags extends StatelessWidget {
  const GroupTags({required this.tags, super.key});
  final List<String> tags;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 5,
    children: tags
        .map(
          (tag) => Text(
            '#$tag',
            style: const TextStyle(
              fontSize: 11,
              color: HantuckColors.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        )
        .toList(),
  );
}

class GroupPageHeader extends StatelessWidget {
  const GroupPageHeader({
    required this.title,
    required this.backKey,
    this.trailing,
    super.key,
  });
  final String title;
  final String backKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: ValueKey(backKey),
        tooltip: '뒤로가기',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ),
      ?trailing,
    ],
  );
}

class GroupListCard extends StatelessWidget {
  const GroupListCard({
    required this.group,
    required this.onTap,
    this.status,
    this.showDescription = false,
    this.favorite = false,
    super.key,
  });
  final DemoGroup group;
  final VoidCallback onTap;
  final String? status;
  final bool showDescription;
  final bool favorite;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HantuckColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('group-card-${group.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (favorite)
                          const Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: Color(0xFFE54958),
                            semanticLabel: '즐겨찾기 그룹',
                          ),
                        if (group.locked)
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: HantuckColors.muted,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (showDescription) ...[
                      Text(
                        group.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.7,
                          color: HantuckColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '${group.category} · ${group.code}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: HantuckColors.muted,
                      ),
                    ),
                    const SizedBox(height: 9),
                    GroupTags(tags: group.tags),
                    if (status != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        status!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: HantuckColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GroupThumbnail(group: group, size: 64),
            ],
          ),
        ),
      ),
    ),
  );
}
