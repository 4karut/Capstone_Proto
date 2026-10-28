import 'package:flutter/material.dart';

class MainNavigation extends InheritedWidget {
  const MainNavigation({
    required this.selectedIndex,
    required this.select,
    required super.child,
    super.key,
  });
  final int selectedIndex;
  final ValueChanged<int> select;

  static MainNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainNavigation>();

  @override
  bool updateShouldNotify(MainNavigation oldWidget) =>
      selectedIndex != oldWidget.selectedIndex;
}
