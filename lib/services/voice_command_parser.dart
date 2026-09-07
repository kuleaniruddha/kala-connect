/// Pure command parsing makes language rules testable without device STT.
abstract final class VoiceCommandParser {
  static ParsedVoiceCommand parse(String transcript) {
    final price = extractPrice(transcript);
    if (price != null) return ParsedVoiceCommand.price(price);

    final extraInfo = RegExp(r'(?:add\s+(?:more\s+)?info|more\s+info)\s*[:,-]?\s*(.+)', caseSensitive: false).firstMatch(transcript)?.group(1) ??
        RegExp(r'जानकारी\s*(?:जोड़ें|जोड़ो)?\s*[:,-]?\s*(.+)').firstMatch(transcript)?.group(1);
    if (extraInfo != null && extraInfo.trim().isNotEmpty) return ParsedVoiceCommand.moreInfo(extraInfo.trim());

    final lower = transcript.toLowerCase();
    if (lower.contains('delete') && lower.contains('image') || transcript.contains('तस्वीर हट')) {
      final ordinal = _imageOrdinal(lower, transcript);
      if (ordinal != null) return ParsedVoiceCommand.deleteImage(ordinal - 1);
    }

    final language = _languageFromTranscript(lower, transcript);
    if (language != null && (lower.contains('translate') || transcript.contains('अनुवाद') || transcript.contains('भाषा'))) {
      return ParsedVoiceCommand.changeLanguage(language);
    }
    return const ParsedVoiceCommand.unknown();
  }

  static int? extractPrice(String transcript) {
    final english = RegExp(r'(?:price|₹|rs\.?|rupees?)\s*(?:to|=|is)?\s*(\d+)', caseSensitive: false).firstMatch(transcript);
    final hindi = RegExp(r'(?:कीमत|दाम)\s*(?:को)?\s*(\d+)').firstMatch(transcript);
    return int.tryParse((english ?? hindi)?.group(1) ?? '');
  }

  static int? _imageOrdinal(String lower, String source) {
    final numeric = RegExp(r'(\d+)').firstMatch(source)?.group(1);
    if (numeric != null) return int.tryParse(numeric);
    if (lower.contains('first') || source.contains('पहली')) return 1;
    if (lower.contains('second') || source.contains('दूसरी')) return 2;
    if (lower.contains('third') || source.contains('तीसरी')) return 3;
    return null;
  }

  static String? _languageFromTranscript(String lower, String source) {
    if (lower.contains('bengali') || source.contains('बंगाली')) return 'bn';
    if (lower.contains('tamil') || source.contains('तमिल')) return 'ta';
    if (lower.contains('telugu') || source.contains('तेलुगु')) return 'te';
    if (lower.contains('marathi') || source.contains('मराठी')) return 'mr';
    if (lower.contains('gujarati') || source.contains('गुजराती')) return 'gu';
    if (lower.contains('english') || source.contains('अंग्रेजी')) return 'en';
    if (lower.contains('hindi') || source.contains('हिंदी')) return 'hi';
    return null;
  }
}

enum VoiceCommandType { price, moreInfo, deleteImage, changeLanguage, unknown }

class ParsedVoiceCommand {
  const ParsedVoiceCommand._(this.type, {this.price, this.text, this.imageIndex, this.languageCode});
  const ParsedVoiceCommand.price(int value) : this._(VoiceCommandType.price, price: value);
  const ParsedVoiceCommand.moreInfo(String value) : this._(VoiceCommandType.moreInfo, text: value);
  const ParsedVoiceCommand.deleteImage(int value) : this._(VoiceCommandType.deleteImage, imageIndex: value);
  const ParsedVoiceCommand.changeLanguage(String value) : this._(VoiceCommandType.changeLanguage, languageCode: value);
  const ParsedVoiceCommand.unknown() : this._(VoiceCommandType.unknown);
  final VoiceCommandType type;
  final int? price;
  final String? text;
  final int? imageIndex;
  final String? languageCode;
}
