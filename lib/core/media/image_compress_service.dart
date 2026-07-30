import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// High-quality image compression for free-tier Storage.
/// Keeps visual fidelity (quality 88) while capping long edge at 1920px.
class ImageCompressService {
  ImageCompressService._();

  static const int maxLongEdge = 1920;
  static const int quality = 88;
  static const int maxBytes = 3 * 1024 * 1024; // soft target ~3 MB
  static const _uuid = Uuid();

  static Future<File> compressToJpeg(File source) async {
    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'img_${_uuid.v4()}.jpg');

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      outPath,
      quality: quality,
      minWidth: maxLongEdge,
      minHeight: maxLongEdge,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (result == null) {
      return source;
    }

    var file = File(result.path);
    var size = await file.length();

    // If still large, gently lower quality (still visually strong).
    if (size > maxBytes) {
      final retryPath = p.join(dir.path, 'img_${_uuid.v4()}_q78.jpg');
      final retry = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        retryPath,
        quality: 78,
        minWidth: maxLongEdge,
        minHeight: maxLongEdge,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (retry != null) {
        file = File(retry.path);
      }
    }

    return file;
  }

  static Future<File> persistLocalCopy({
    required File compressed,
    required String ownerId,
    required String noteId,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(root.path, 'note_media', ownerId, noteId));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final dest = File(p.join(folder.path, 'img_${_uuid.v4()}.jpg'));
    return compressed.copy(dest.path);
  }
}
