import 'package:flutter/material.dart';

Future<bool> remoteUiAction(
  BuildContext context,
  Future<dynamic> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError ? e.message : '요청을 처리하지 못했어요. 다시 시도해 주세요.',
          ),
        ),
      );
    }
    return false;
  }
}
