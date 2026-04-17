library;

import 'package:flutter/material.dart';

export 'src/u_button.dart';
export 'src/u_input.dart';
export 'src/u_scroll_picker.dart';
export 'src/u_file_list_widget.dart';
export 'src/u_navigation_bar.dart';
export 'src/u_tree_view.dart';
export 'src/u_split_layout.dart';
export 'src/u_split_panel.dart';
export 'src/u_tree_navigator.dart';

class UWidget {
  static IconData getFileIcon(String fileName, {bool isDirectory = false}) {
    if (isDirectory) {
      return Icons.folder;
    }

    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'txt':
      case 'md':
      case 'log':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case 'mkv':
        return Icons.video_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive;
      case 'exe':
      case 'msi':
        return Icons.computer;
      case 'apk':
        return Icons.android;
      case 'dmg':
      case 'pkg':
        return Icons.apple;
      case 'html':
      case 'htm':
      case 'css':
      case 'js':
        return Icons.code;
      case 'dart':
        return Icons.flutter_dash;
      case 'json':
        return Icons.data_object;
      case 'xml':
        return Icons.data_array;
      default:
        return Icons.insert_drive_file;
    }
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
}
