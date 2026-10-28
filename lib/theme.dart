import 'package:flutter/material.dart';

abstract final class HantuckColors {
  static const orange = Color(0xFFE46B35);
  static const orangeSoft = Color(0xFFFFF0E7);
  static const ink = Color(0xFF282523);
  static const muted = Color(0xFF797570);
  static const border = Color(0xFFE7E3DF);
  static const canvas = Color(0xFFF6F3EF);
}

ThemeData buildHantuckTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: HantuckColors.orange,
    primary: HantuckColors.orange,
    surface: Colors.white,
    onSurface: HantuckColors.ink,
    error: const Color(0xFFBE3A35),
  );
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansKR',
    colorScheme: scheme,
    scaffoldBackgroundColor: HantuckColors.canvas,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: .18),
      selectionHandleColor: scheme.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFCFBFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF99948F)),
      errorStyle: const TextStyle(fontSize: 11, height: 1.4),
      errorMaxLines: 2,
      border: border(HantuckColors.border),
      enabledBorder: border(HantuckColors.border),
      focusedBorder: border(HantuckColors.orange, 1.5),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: HantuckColors.orange,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class AuthPage extends StatelessWidget {
  const AuthPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: wide ? 32 : 0),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 460,
                  minHeight: wide ? 0 : constraints.maxHeight,
                ),
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(wide ? 24 : 0),
                  border: wide ? Border.all(color: HantuckColors.border) : null,
                  boxShadow: wide
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .025),
                            blurRadius: 36,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : null,
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class HantuckBrand extends StatelessWidget {
  const HantuckBrand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: HantuckColors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.volunteer_activism_rounded,
          size: 22,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 9),
      const Text(
        '한턱',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.4,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          '함께 나누는 따뜻한 마음',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, color: HantuckColors.muted),
        ),
      ),
    ],
  );
}
