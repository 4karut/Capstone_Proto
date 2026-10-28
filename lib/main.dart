import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'demo_auth_store.dart';
import 'login_screen.dart';
import 'theme.dart';

void main() => runApp(const HantuckApp());

class HantuckApp extends StatefulWidget {
  const HantuckApp({this.authStore, super.key});

  final DemoAuthStore? authStore;

  @override
  State<HantuckApp> createState() => _HantuckAppState();
}

class _HantuckAppState extends State<HantuckApp> {
  late final _auth = widget.authStore ?? DemoAuthStore();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '한턱',
    debugShowCheckedModeBanner: false,
    theme: buildHantuckTheme(),
    locale: const Locale('ko', 'KR'),
    supportedLocales: const [Locale('ko', 'KR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: LoginScreen(auth: _auth),
  );
}
