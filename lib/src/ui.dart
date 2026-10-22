import 'package:flutter/material.dart';

import 'store.dart';
import 'models.dart';

const coral = Color(0xFFED6A50);
const ink = Color(0xFF2D332E);
const muted = Color(0xFF858982);
const canvas = Color(0xFFFAF9F6);
const line = Color(0xFFEEEDE7);
const green = Color(0xFF438266);
IconData foodIcon(Shop shop) => switch (shop.category) {
  '카페' => Icons.local_cafe_rounded,
  '베이커리' => Icons.bakery_dining_rounded,
  '샐러드' => Icons.eco_rounded,
  _ => Icons.rice_bowl_rounded,
};

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);
  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

AppStore storeOf(BuildContext context) => AppScope.of(context);
Future<T?> open<T>(BuildContext c, Widget page) =>
    Navigator.of(c).push<T>(MaterialPageRoute(builder: (_) => page));
void toast(BuildContext c, String text) => ScaffoldMessenger.of(c).showSnackBar(
  SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
);

class PageFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottom;
  final List<Widget>? actions;
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.actions,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: child,
    bottomNavigationBar: bottom == null
        ? null
        : SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: line)),
              ),
              child: bottom,
            ),
          ),
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: line),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, this.color = green});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class Primary extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  const Primary(this.text, {super.key, this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton(
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
          Flexible(child: Text(text)),
        ],
      ),
    ),
  );
}

class InfoRow extends StatelessWidget {
  final String label, value;
  final bool accent;
  const InfoRow(this.label, this.value, {super.key, this.accent = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: accent ? coral : ink,
              fontSize: accent ? 18 : 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, body;
  final VoidCallback? reset;
  const EmptyState(this.title, this.body, {super.key, this.reset});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
    child: Center(
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: muted, size: 44),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.6),
          ),
          if (reset != null)
            TextButton(onPressed: reset, child: const Text('조건 초기화')),
        ],
      ),
    ),
  );
}

class ShopArt extends StatelessWidget {
  final Shop shop;
  final double height;
  const ShopArt(this.shop, {super.key, this.height = 150});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Color(shop.color),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -15,
          top: -35,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .25),
            ),
          ),
        ),
        Positioned(
          left: -20,
          bottom: -70,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .35),
                width: 20,
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: height * .8,
            height: height * .8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF705832).withValues(alpha: .08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              foodIcon(shop),
              size: height * .43,
              color: const Color(0xFF8C6949),
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 14,
          child: Pill(shop.category, color: const Color(0xFF685745)),
        ),
        const Positioned(
          right: 14,
          bottom: 12,
          child: Text(
            'HANTTEOK LOCAL',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: Color(0xFF776C59),
            ),
          ),
        ),
      ],
    ),
  );
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}

Widget paddedList(List<Widget> children) => ListView(
  padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
  children: children,
);
Widget note(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Text(
    text,
    style: const TextStyle(color: muted, fontSize: 12, height: 1.7),
  ),
);
