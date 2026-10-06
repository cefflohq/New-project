import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Marketplace Verification evidence (licence front, licence back, vehicle)
/// must be a live camera capture: no gallery / files / existing image.
void main() {
  final src = File('lib/ui/screens/documents.dart').readAsStringSync();

  test('verification screen never opens the gallery or a file picker', () {
    expect(src.contains('ImageSource.gallery'), isFalse);
    expect(src.contains('pickMultiImage'), isFalse);
    expect(src.contains('FilePicker'), isFalse);
    expect(src.contains('chooseFromGallery'), isFalse);
  });

  test('every capture goes through the camera-only liveCapture()', () {
    final picks = RegExp(r'pickImage\(').allMatches(src).length;
    expect(picks, 1, reason: 'only liveCapture() may call pickImage');
    expect(src, contains('source: ImageSource.camera'));
    expect(RegExp(r'liveCapture\(\)').allMatches(src).length, 3,
        reason: 'definition + licence sides + vehicle');
  });

  test('licence needs exactly front + back before Continue', () {
    expect(src, contains('_front == null || _back == null ? null : _submit'));
  });
}
