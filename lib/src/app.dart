import 'package:flutter/material.dart';

import 'store.dart';
import 'ui.dart';
import 'pages/home.dart';
import 'pages/account.dart';
import 'pages/history.dart';

class HantteokApp extends StatelessWidget {
  final AppStore store;
  const HantteokApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) => AppScope(
    store: store,
    child: MaterialApp(
      title: '한턱 · 마음을 나누는 한 끼',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansKR',
        fontFamilyFallback: const [
          'Apple SD Gothic Neo',
          'Noto Sans CJK KR',
          'sans-serif',
        ],
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: coral,
          primary: coral,
          surface: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'NotoSansKR',
          bodyColor: ink,
          displayColor: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'NotoSansKR',
            color: ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: coral,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          hintStyle: const TextStyle(color: muted, fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: coral),
          ),
        ),
        dividerTheme: const DividerThemeData(color: line, thickness: 1),
      ),
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFEDECE6),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Color(0x16000000), blurRadius: 45)],
            ),
            child: ClipRect(child: child!),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: store,
        builder: (context, _) =>
            store.loggedIn ? const AppShell() : const LoginPage(),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final store = storeOf(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (store.storageError != null)
              MaterialBanner(
                content: Text(
                  store.storageError!,
                  style: const TextStyle(fontSize: 12),
                ),
                actions: [
                  TextButton(
                    onPressed: store.dismissStorageError,
                    child: const Text('닫기'),
                  ),
                ],
              ),
            Expanded(
              child: IndexedStack(
                index: index,
                children: [
                  HomePage(onExplore: () => setState(() => index = 1)),
                  const ExplorePage(),
                  const HistoryPage(),
                  const ProfilePage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 74,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFFFECE6),
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: coral),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: coral),
            label: '가게 찾기',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: coral),
            label: '내역',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: coral),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
