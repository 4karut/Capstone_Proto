import 'package:flutter/material.dart';

import 'demo_auth_store.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'main_navigation.dart';
import 'my_page_screen.dart';
import 'store_search_screen.dart';
import 'theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({required this.auth, required this.account, super.key});
  final DemoAuthStore auth;
  final DemoAccount account;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _navigator = GlobalKey<NavigatorState>();
  int _selectedIndex = 0;

  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).clearSnackBars();
    _navigator.currentState?.popUntil((route) => route.isFirst);
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) => MainNavigation(
    selectedIndex: _selectedIndex,
    select: _select,
    child: Scaffold(
      body: NavigatorPopHandler<void>(
        onPopWithResult: (_) => _navigator.currentState?.pop(),
        child: Navigator(
          key: _navigator,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) =>
                _Destinations(auth: widget.auth, account: widget.account),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: HantuckColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: NavigationBar(
                height: 72,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                indicatorColor: HantuckColors.orangeSoft,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _select,
                labelTextStyle: const WidgetStatePropertyAll(
                  TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                destinations: const [
                  NavigationDestination(
                    key: ValueKey('nav-home'),
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(
                      Icons.home_rounded,
                      color: HantuckColors.orange,
                    ),
                    label: '홈',
                  ),
                  NavigationDestination(
                    key: ValueKey('nav-stores'),
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(
                      Icons.storefront_rounded,
                      color: HantuckColors.orange,
                    ),
                    label: '가게 찾기',
                  ),
                  NavigationDestination(
                    key: ValueKey('nav-favorites'),
                    icon: Icon(Icons.star_border_rounded),
                    selectedIcon: Icon(
                      Icons.star_rounded,
                      color: HantuckColors.orange,
                    ),
                    label: '즐겨찾기',
                  ),
                  NavigationDestination(
                    key: ValueKey('nav-my-page'),
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(
                      Icons.person_rounded,
                      color: HantuckColors.orange,
                    ),
                    label: '마이페이지',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Destinations extends StatelessWidget {
  const _Destinations({required this.auth, required this.account});
  final DemoAuthStore auth;
  final DemoAccount account;

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: MainNavigation.maybeOf(context)!.selectedIndex,
    children: [
      HomeScreen(auth: auth, account: account),
      StoreSearchScreen(auth: auth, account: account),
      FavoritesScreen(auth: auth, account: account),
      MyPageScreen(auth: auth, account: account),
    ],
  );
}
