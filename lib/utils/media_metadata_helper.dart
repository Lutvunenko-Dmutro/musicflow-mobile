import 'dart:typed_data';
import 'package:audiotags/audiotags.dart';
import 'package:image/image.dart' as img;
import 'package:music_flow_mobile/utils/app_logger.dart';

class MediaMetadataHelper {
  /// Smart crops YouTube cover art to a 1:1 square, removing black letterboxing if present.
  static Uint8List? cropCoverArtToSquare(Uint8List? originalBytes) {
    if (originalBytes == null) return null;

    try {
      final image = img.decodeImage(originalBytes);
      if (image == null) return originalBytes;

      int cropX = 0;
      int cropY = 0;
      int cropWidth = image.width;
      int cropHeight = image.height;

      // Detect 4:3 YouTube letterboxing and remove it
      if ((image.width * 3 - image.height * 4).abs() <= 1) {
        cropHeight = (image.width * 9) ~/ 16;
        cropY = (image.height - cropHeight) ~/ 2;
      }

      // Crop to 1:1 square
      int size = cropWidth < cropHeight ? cropWidth : cropHeight;
      int x = cropX + (cropWidth - size) ~/ 2;
      int y = cropY + (cropHeight - size) ~/ 2;
      
      final croppedImage = img.copyCrop(image, x: x, y: y, width: size, height: size);
      
      AppLogger.download('Cover art smart-cropped to 1:1 square.');
      return Uint8List.fromList(img.encodeJpg(croppedImage, quality: 95));
    } catch (e) {
      AppLogger.warning('Failed to crop cover art: $e', 'METADATA');
      return originalBytes;
    }
  }

  /// Embeds ID3 tags (Title, Artist, Cover) into an audio file (e.g., M4A/MP3)
  static Future<void> embedTags({
    required String filePath,
    required String title,
    required String artist,
    Uint8List? coverBytes,
  }) async {
    try {
      AppLogger.download('Embedding tags...');
      final pictures = <Picture>[];
      if (coverBytes != null) {
        pictures.add(
          Picture(
            bytes: coverBytes,
            mimeType: MimeType.jpeg,
            pictureType: PictureType.coverFront,
          ),
        );
      }

      await AudioTags.write(
        filePath,
        Tag(
          title: title,
          trackArtist: artist,
          pictures: pictures,
        ),
      );
      AppLogger.success('Tags embedded successfully!', 'METADATA');
    } catch (e) {
      AppLogger.warning('audiotags failed to embed: $e', 'METADATA');
      // Throw exception if we want caller to handle it (currently we just log and ignore)
    }
  }
}
