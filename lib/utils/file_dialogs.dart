import 'dart:io';

import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/linux_portal_file_chooser.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:file_picker/file_picker.dart';

/// Open/save file dialogs that also work inside a Flatpak and on Linux phones.
///
/// On Linux, file_picker needs zenity, kdialog or qarma on PATH. When none is
/// available (Flatpak sandbox, most phone images) or we run in a Linux phone session,
/// the xdg-desktop-portal FileChooser is used instead. Everywhere else this is a thin
/// wrapper around file_picker, so behaviour on Android/iOS/macOS/Windows is unchanged.
class FileDialogs {
  static Future<String?> pickFilePath({String dialogTitle = 'Open file'}) async {
    if (await _shouldUsePortal()) {
      try {
        return await LinuxPortalFileChooser.openFile(title: dialogTitle);
      } catch (e) {
        printV('xdg-desktop-portal OpenFile failed, falling back to file_picker: $e');
      }
    }
    final result = await FilePicker.platform.pickFiles(dialogTitle: dialogTitle);
    if (result == null || result.files.isEmpty) return null;
    return result.files.first.path;
  }

  static Future<String?> saveFilePath({
    required String dialogTitle,
    required String fileName,
  }) async {
    if (await _shouldUsePortal()) {
      try {
        return await LinuxPortalFileChooser.saveFile(title: dialogTitle, fileName: fileName);
      } catch (e) {
        printV('xdg-desktop-portal SaveFile failed, falling back to file_picker: $e');
      }
    }
    return FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      lockParentWindow: true,
    );
  }

  static bool? _hasCliPicker;

  static Future<bool> _shouldUsePortal() async {
    if (!Platform.isLinux) return false;
    if (LinuxPortalFileChooser.isFlatpak || DeviceInfo.instance.isLinuxMobile) return true;
    _hasCliPicker ??= await _anyOnPath(const ['zenity', 'kdialog', 'qarma']);
    return !_hasCliPicker!;
  }

  static Future<bool> _anyOnPath(List<String> executables) async {
    final path = Platform.environment['PATH'] ?? '';
    for (final dir in path.split(':')) {
      if (dir.isEmpty) continue;
      for (final exe in executables) {
        if (await File('$dir/$exe').exists()) return true;
      }
    }
    return false;
  }
}
