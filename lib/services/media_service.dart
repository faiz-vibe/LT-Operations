import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MediaService {
  /// Photo ko temporary location se app ke permanent folder me save karta hai.
  /// Returns the permanent path of the saved image.
  static Future<String> saveImagePermanently(String tempPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final ext = tempPath.split('.').last;
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final permanentPath = '${directory.path}/$fileName';

    final File tempFile = File(tempPath);
    await tempFile.copy(permanentPath);

    return permanentPath;
  }
}