import 'package:flutter_test/flutter_test.dart';
import 'package:kala_connect/services/voice_command_parser.dart';

void main() {
  group('VoiceCommandParser.extractPrice', () {
    test('extracts an English price-edit command', () {
      expect(VoiceCommandParser.extractPrice('Change the price to 500'), 500);
    });

    test('extracts an INR amount', () {
      expect(VoiceCommandParser.extractPrice('price ₹1250'), 1250);
    });

    test('extracts a Hindi price-edit command', () {
      expect(VoiceCommandParser.extractPrice('कीमत 750 कर दो'), 750);
    });

    test('returns null where no price exists', () {
      expect(VoiceCommandParser.extractPrice('लाल रंग जोड़ें'), isNull);
    });
  });

  group('VoiceCommandParser.parse', () {
    test('parses more-info editing command', () {
      final command = VoiceCommandParser.parse('add more info: it is made of bamboo');
      expect(command.type, VoiceCommandType.moreInfo);
      expect(command.text, 'it is made of bamboo');
    });

    test('parses gallery deletion command', () {
      final command = VoiceCommandParser.parse('delete third image');
      expect(command.type, VoiceCommandType.deleteImage);
      expect(command.imageIndex, 2);
    });

    test('parses a translation language command', () {
      final command = VoiceCommandParser.parse('translate to Bengali');
      expect(command.type, VoiceCommandType.changeLanguage);
      expect(command.languageCode, 'bn');
    });
  });
}
