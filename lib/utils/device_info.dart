import 'dart:io';

class DeviceInfo {
  DeviceInfo._();

  static DeviceInfo get instance => DeviceInfo._();

  bool get isMobile => Platform.isAndroid || Platform.isIOS;

  bool get isDesktop => Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// True when running on Linux in a phone/tablet session (Phosh, Plasma Mobile,
  /// Sxmo, ...), e.g. postmarketOS, Mobian or other Linux phones.
  ///
  /// Such builds still report [isDesktop] (they use the GTK embedder and none of the
  /// Android/iOS-only plugins exist), but phone-oriented UI decisions should use this.
  /// Can be forced with `CAKEWALLET_FORM_FACTOR=mobile` or `CAKEWALLET_FORM_FACTOR=desktop`.
  bool get isLinuxMobile => _isLinuxMobileSession;

  /// Whether a camera based QR scanner backend (fast_scanner) exists on this platform.
  /// fast_scanner only implements Android, iOS, macOS and web.
  bool get hasCameraQrScanner => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  static final bool _isLinuxMobileSession =
      Platform.isLinux && detectLinuxMobileSession(Platform.environment);

  /// Pure function so it can be unit tested with a fake environment.
  static bool detectLinuxMobileSession(Map<String, String> env) {
    final override = env['CAKEWALLET_FORM_FACTOR']?.trim().toLowerCase();
    if (override == 'mobile' || override == 'phone' || override == 'handset') return true;
    if (override == 'desktop') return false;

    final desktops = [
      env['XDG_CURRENT_DESKTOP'],
      env['XDG_SESSION_DESKTOP'],
      env['DESKTOP_SESSION'],
    ].whereType<String>().join(':').toLowerCase();
    if (desktops.contains('phosh') || desktops.contains('sxmo') || desktops.contains('lomiri')) {
      return true;
    }

    // Plasma Mobile sets PLASMA_PLATFORM=phone:handset
    final plasmaPlatform = env['PLASMA_PLATFORM']?.toLowerCase() ?? '';
    if (plasmaPlatform.contains('phone') ||
        plasmaPlatform.contains('handset') ||
        plasmaPlatform.contains('mobile')) {
      return true;
    }

    return false;
  }
}
