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
    // 1. Prefix with keyword: "price to 850", "₹850", "rs 850", "rupees 850", "कीमत 850", "दाम 850", "rate 850"
    final prefixMatch = RegExp(
      r'(?:price|cost|rate|₹|rs\.?|rupees?|rupaye|रुपये|कीमत|दाम|रेट)\s*(?:to|=|is|हो|रखो|करो|कर\s+दो)?\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (prefixMatch != null) {
      final val = int.tryParse(prefixMatch.group(1) ?? '');
      if (val != null && val > 0) return val;
    }

    // 2. Suffix with currency: "850 rupees", "850 rupaye", "850 rs", "850 रुपये"
    final suffixMatch = RegExp(
      r'(\d+)\s*(?:rupees?|rs\.?|rupaye|रुपये|₹|inr|टका)',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (suffixMatch != null) {
      final val = int.tryParse(suffixMatch.group(1) ?? '');
      if (val != null && val > 0) return val;
    }

    // 3. Command style: "change price to 500", "set to 850", "make it 850"
    final commandMatch = RegExp(
      r'(?:set|change|make)\s+(?:the\s+)?(?:price\s+)?(?:to\s+)?(\d+)',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (commandMatch != null) {
      final val = int.tryParse(commandMatch.group(1) ?? '');
      if (val != null && val > 0) return val;
    }

    // 4. Standalone number in voice input (e.g. "850", "₹850")
    final pureNumberMatch = RegExp(r'^\s*(?:₹|rs\.?)?\s*(\d{2,6})\s*$', caseSensitive: false).firstMatch(transcript.trim());
    if (pureNumberMatch != null) {
      final val = int.tryParse(pureNumberMatch.group(1) ?? '');
      if (val != null && val > 0) return val;
    }

    return null;
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
