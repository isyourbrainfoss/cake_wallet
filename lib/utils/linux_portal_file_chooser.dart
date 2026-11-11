import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dbus/dbus.dart';

/// Minimal client for the xdg-desktop-portal FileChooser interface
/// (https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.FileChooser.html).
///
/// file_picker's Linux backend shells out to zenity/kdialog/qarma, which are missing
/// inside a Flatpak sandbox and on many Linux phone images. The portal works in both
/// cases (Phosh, Plasma Mobile and GNOME/KDE desktops all ship a backend) and grants
/// the sandbox access to exactly the file the user picked.
class LinuxPortalFileChooser {
  static const _portalBusName = 'org.freedesktop.portal.Desktop';
  static const _portalPath = '/org/freedesktop/portal/desktop';
  static const _fileChooserInterface = 'org.freedesktop.portal.FileChooser';
  static const _requestInterface = 'org.freedesktop.portal.Request';

  /// Returns the selected file path, or null if the user cancelled.
  /// Throws if no portal is available.
  static Future<String?> openFile({String title = 'Open file'}) =>
      _request('OpenFile', title, const {});

  /// Returns the path the user chose to save to, or null if the user cancelled.
  /// Throws if no portal is available.
  static Future<String?> saveFile({required String title, String? fileName}) => _request(
    'SaveFile',
    title,
    {if (fileName != null && fileName.isNotEmpty) 'current_name': DBusString(fileName)},
  );

  static Future<String?> _request(
    String method,
    String title,
    Map<String, DBusValue> extraOptions,
  ) async {
    final client = DBusClient.session();
    StreamSubscription<DBusSignal>? subscription;
    try {
      final token = 'cake_wallet_${Random.secure().nextInt(1 << 31)}';
      final responses = <DBusSignal>[];
      DBusObjectPath? handle;
      final completer = Completer<DBusSignal>();

      // Subscribe before calling so the Response signal can't be missed.
      subscription =
          DBusSignalStream(
            client,
            sender: _portalBusName,
            interface: _requestInterface,
            name: 'Response',
          ).listen((signal) {
            if (completer.isCompleted) return;
            if (handle == null) {
              responses.add(signal);
            } else if (signal.path == handle) {
              completer.complete(signal);
            }
          });

      final reply = await client.callMethod(
        destination: _portalBusName,
        path: DBusObjectPath(_portalPath),
        interface: _fileChooserInterface,
        name: method,
        values: [
          const DBusString(''), // parent window
          DBusString(title),
          DBusDict.stringVariant({
            'handle_token': DBusString(token),
            'modal': const DBusBoolean(true),
            ...extraOptions,
          }),
        ],
        replySignature: DBusSignature('o'),
      );
      handle = reply.values.first.asObjectPath();
      for (final signal in responses) {
        if (signal.path == handle && !completer.isCompleted) completer.complete(signal);
      }

      final response = await completer.future;
      final code = response.values[0].asUint32();
      if (code != 0) return null; // 1 = cancelled, 2 = other error/closed

      final results = response.values[1].asStringVariantDict();
      final uris = results['uris']?.asStringArray().toList() ?? const <String>[];
      if (uris.isEmpty) return null;
      final uri = Uri.parse(uris.first);
      return uri.scheme == 'file' ? uri.toFilePath() : null;
    } finally {
      await subscription?.cancel();
      await client.close();
    }
  }

  /// True when running inside a Flatpak sandbox.
  static bool get isFlatpak => File('/.flatpak-info').existsSync();
}
