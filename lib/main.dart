import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'demo_auth_store.dart';
import 'login_screen.dart';
import 'theme.dart';
import 'main_screen.dart';
import 'server_gateway.dart';
import 'server_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gateway = ServerGateway();
  final auth = DemoAuthStore(seedDemoAccount: false, gateway: gateway);
  await auth.initializeRemote();
  runApp(HantuckApp(authStore: auth));
}

class HantuckApp extends StatefulWidget {
  const HantuckApp({this.authStore, super.key});

  final DemoAuthStore? authStore;

  @override
  State<HantuckApp> createState() => _HantuckAppState();
}

class _HantuckAppState extends State<HantuckApp> {
  late final _auth = widget.authStore ?? DemoAuthStore();

  @override
  void initState() {
    super.initState();
    _auth.gateway?.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _auth.gateway?.removeListener(_changed);
    if (widget.authStore == null) _auth.gateway?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    key: ValueKey(_auth.gateway?.sessionEpoch ?? 0),
    title: '한턱',
    debugShowCheckedModeBanner: false,
    theme: buildHantuckTheme(),
    locale: const Locale('ko', 'KR'),
    supportedLocales: const [Locale('ko', 'KR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => Stack(
      children: [
        Column(
          children: [
            if (_auth.gateway?.error != null)
              Material(
                color: Colors.orange.shade50,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            _auth.gateway!.error!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            remoteUiAction(context, _auth.gateway!.refresh),
                        child: const Text('새로고침'),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: child!),
          ],
        ),
        if (_auth.gateway?.busy == true) ...[
          const Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Color(0x33000000)),
          ),
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ],
    ),
    home: _auth.serverAccount == null
        ? LoginScreen(auth: _auth)
        : MainScreen(auth: _auth, account: _auth.serverAccount!),
  );
}
