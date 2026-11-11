import 'package:cake_wallet/utils/device_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceInfo.detectLinuxMobileSession', () {
    bool detect(Map<String, String> env) => DeviceInfo.detectLinuxMobileSession(env);

    test('Phosh session is mobile', () {
      expect(detect({'XDG_CURRENT_DESKTOP': 'Phosh:GNOME'}), isTrue);
    });

    test('Plasma Mobile session is mobile', () {
      expect(detect({'XDG_CURRENT_DESKTOP': 'KDE', 'PLASMA_PLATFORM': 'phone:handset'}), isTrue);
    });

    test('Sxmo session is mobile', () {
      expect(detect({'XDG_SESSION_DESKTOP': 'sxmo'}), isTrue);
    });

    test('regular desktops are not mobile', () {
      expect(detect({'XDG_CURRENT_DESKTOP': 'GNOME'}), isFalse);
      expect(detect({'XDG_CURRENT_DESKTOP': 'KDE'}), isFalse);
      expect(detect({}), isFalse);
    });

    test('CAKEWALLET_FORM_FACTOR overrides detection', () {
      expect(detect({'XDG_CURRENT_DESKTOP': 'GNOME', 'CAKEWALLET_FORM_FACTOR': 'mobile'}), isTrue);
      expect(
        detect({'XDG_CURRENT_DESKTOP': 'Phosh:GNOME', 'CAKEWALLET_FORM_FACTOR': 'desktop'}),
        isFalse,
      );
    });
  });
}
