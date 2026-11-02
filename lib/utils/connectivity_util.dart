import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cw_core/utils/print_verbose.dart';

/// Wrapper around [Connectivity.checkConnectivity] that never throws.
///
/// On Linux, connectivity_plus queries NetworkManager over the system D-Bus.
/// When there is no system bus or no NetworkManager (minimal images,
/// containers, systemd-networkd/connman setups) the plugin fails
/// asynchronously from inside a D-Bus stream listener, so the error escapes
/// the caller's try/catch and ends up in the global error handler (error
/// report popup). In that case we cannot tell, so assume we are online
/// ([ConnectivityResult.other]) and let the node requests decide.
Future<List<ConnectivityResult>> checkConnectivitySafe() async {
  if (!Platform.isLinux) {
    try {
      return await Connectivity().checkConnectivity();
    } catch (e) {
      printV('checkConnectivity failed: $e');
      return const [ConnectivityResult.other];
    }
  }

  if (!_isLinuxSystemBusAvailable()) {
    return const [ConnectivityResult.other];
  }

  final completer = Completer<List<ConnectivityResult>>();
  runZonedGuarded(() async {
    final result = await Connectivity().checkConnectivity();
    if (!completer.isCompleted) completer.complete(result);
  }, (error, _) {
    printV('checkConnectivity failed: $error');
    if (!completer.isCompleted) completer.complete(const [ConnectivityResult.other]);
  });

  return completer.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () => const [ConnectivityResult.other],
  );
}

bool _isLinuxSystemBusAvailable() {
  final address = Platform.environment['DBUS_SYSTEM_BUS_ADDRESS'];
  if (address != null && address.isNotEmpty) {
    const prefix = 'unix:path=';
    if (!address.startsWith(prefix)) return true;
    return _exists(address.substring(prefix.length).split(',').first);
  }
  return _exists('/run/dbus/system_bus_socket') || _exists('/var/run/dbus/system_bus_socket');
}

bool _exists(String path) =>
    FileSystemEntity.typeSync(path, followLinks: true) != FileSystemEntityType.notFound;
