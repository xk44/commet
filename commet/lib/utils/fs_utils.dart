import 'dart:io';

import 'package:commet/debug/log.dart';

class FsUtils {
  /// Ensures [path] exists as a directory.
  ///
  /// If a file already exists at [path], it is removed and replaced with a
  /// directory so startup-critical paths do not fail with type mismatches.
  static Future<void> ensureDirectoryPath(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);

    if (type == FileSystemEntityType.file) {
      Log.w("Replacing non-directory path with directory: $path");
      await File(path).delete();
    } else if (type == FileSystemEntityType.link) {
      Log.w("Replacing non-directory path with directory: $path");
      await Link(path).delete();
    }

    if (type != FileSystemEntityType.directory) {
      await Directory(path).create(recursive: true);
    }
  }
}
