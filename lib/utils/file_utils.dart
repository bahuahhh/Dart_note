
import 'dart:io';

class FileUtils {

  static String getFileSize(int fileSize) {

    String result = "";

    if (fileSize < 1024) {
      result = '${fileSize.toStringAsFixed(2)}B';
    } else if (1024 <= fileSize && fileSize < 1048576) {
      result = '${(fileSize / 1024).toStringAsFixed(2)}KB';
    } else if (1048576 <= fileSize && fileSize < 1073741824) {
      result = '${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB';
    }

    return result;
  }

  static Future<bool> isDirectoryExist(String path) async{
    File file = File(path);
    return await file.exists();
  }

  static Future<void> createDirectory(String path) async {
    Directory directory = Directory(path);
    directory.create(recursive: true);
  }

}

