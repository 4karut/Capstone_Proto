import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

import 'prepaid_usage_store.dart';

Future<UsagePhoto?> pickThanksPhoto() async {
  final file = await FilePicker.pickFile(
    dialogTitle: '감사 사진 선택',
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
  );
  if (file == null) return null;
  final length = await file.length();
  if (length == null || length <= 0 || length > UsagePhoto.maxBytes) {
    throw StateError('최대 5MB의 사진 1장을 선택해 주세요.');
  }
  final photo = UsagePhoto(name: file.name, bytes: await file.readAsBytes());
  try {
    final codec = await ui.instantiateImageCodec(
      photo.bytes,
      targetWidth: 1200,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();
  } catch (_) {
    throw StateError('사진을 읽을 수 없어요. 다른 JPG·PNG·WebP 파일을 선택해 주세요.');
  }
  return photo;
}
