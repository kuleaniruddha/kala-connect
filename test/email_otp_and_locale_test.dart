import 'package:flutter_test/flutter_test.dart';
import 'package:kala_connect/l10n/app_localizations.dart';
import 'package:kala_connect/services/email_otp_service.dart';

void main() {
  group('EmailOtpService Tests', () {
    test('sendOtp generates valid 6-digit code and rate limits resends', () async {
      final otpService = EmailOtpService();
      final email = 'test_artisan_${DateTime.now().millisecondsSinceEpoch}@kalaconnect.in';

      final result = await otpService.sendOtp(email);
      expect(result.success, true);
      expect(result.otpCode.length, 6);
      expect(int.tryParse(result.otpCode) != null, true);

      // Immediate resend should trigger cooldown
      final resendResult = await otpService.sendOtp(email);
      expect(resendResult.success, false);
      expect(resendResult.secondsRemaining > 0, true);

      // Verify OTP correctly
      final isVerified = otpService.verifyOtp(email: email, enteredOtp: result.otpCode);
      expect(isVerified, true);

      // Same OTP cannot be used twice
      final reused = otpService.verifyOtp(email: email, enteredOtp: result.otpCode);
      expect(reused, false);
    });

    test('rejects invalid email formats and wrong OTPs', () async {
      final otpService = EmailOtpService();
      final invalidResult = await otpService.sendOtp('invalid-email-address');
      expect(invalidResult.success, false);

      final validResult = await otpService.sendOtp('valid_${DateTime.now().millisecondsSinceEpoch}@artisan.in');
      expect(validResult.success, true);

      final wrongOtp = otpService.verifyOtp(email: 'valid@artisan.in', enteredOtp: '000000');
      expect(wrongOtp, false);
    });
  });

  group('AppLocalizations Tests', () {
    test('Translates keys across English, Hindi, and regional languages', () {
      final en = AppLocalizations('en');
      expect(en.translate('tab_shop'), 'Shop');
      expect(en.translate('add_to_cart'), 'Add to Cart');

      final hi = AppLocalizations('hi');
      expect(hi.translate('tab_shop'), 'दुकान');
      expect(hi.translate('add_to_cart'), 'कार्ट में जोड़ें');

      final mr = AppLocalizations('mr');
      expect(mr.translate('tab_shop'), 'बाजार');

      final bn = AppLocalizations('bn');
      expect(bn.translate('tab_shop'), 'দোকান');

      final ta = AppLocalizations('ta');
      expect(ta.translate('tab_shop'), 'கடை');

      final te = AppLocalizations('te');
      expect(te.translate('tab_shop'), 'దుకాణం');

      final gu = AppLocalizations('gu');
      expect(gu.translate('tab_shop'), 'દુકાન');
    });

    test('Falls back gracefully to English when key is missing or locale is unknown', () {
      final fallback = AppLocalizations('xx');
      expect(fallback.translate('tab_shop'), 'Shop');
      expect(fallback.translate('unknown_key_xyz'), 'unknown_key_xyz');
    });
  });
}
