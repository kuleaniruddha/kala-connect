/// Compact first-party copy catalog. English is the default until the artisan
/// finishes choosing a language; each authenticated profile selects its copy.
class AppCopy {
  const AppCopy._(this.languageCode);

  final String languageCode;

  static AppCopy forLanguage(String? languageCode) => AppCopy._(languageCode ?? 'en');

  String get greeting => switch (languageCode) {
        'hi' => 'नमस्ते', 'bn' => 'নমস্কার', 'ta' => 'வணக்கம்', 'te' => 'నమస్కారం',
        'mr' => 'नमस्कार', 'gu' => 'નમસ્તે', 'kn' => 'ನಮಸ್ಕಾರ', 'ml' => 'നമസ്കാരം',
        'or' => 'ନମସ୍କାର', 'pa' => 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ', _ => 'Hello',
      };

  String get scanPrompt => switch (languageCode) {
        'hi' => 'आज किस कला को दुनिया दिखाएँ?', 'bn' => 'আজ কোন শিল্পটি বিশ্বকে দেখাবেন?',
        'ta' => 'இன்று எந்தக் கலையை உலகிற்குக் காட்ட விரும்புகிறீர்கள்?',
        'te' => 'ఈ రోజు ఏ కళను ప్రపంచానికి చూపించాలనుకుంటున్నారు?',
        'mr' => 'आज कोणती कला जगाला दाखवणार?', 'gu' => 'આજે કઈ કળા દુનિયાને બતાવશો?',
        'kn' => 'ಇಂದು ಯಾವ ಕಲೆಯನ್ನು ಜಗತ್ತಿಗೆ ತೋರಿಸುತ್ತೀರಿ?', 'ml' => 'ഇന്ന് ഏത് കലയാണ് ലോകത്തിന് കാണിക്കുന്നത്?',
        'or' => 'ଆଜି କେଉଁ କଳା ଦୁନିଆକୁ ଦେଖାଇବେ?', 'pa' => 'ਅੱਜ ਕਿਹੜੀ ਕਲਾ ਦੁਨੀਆ ਨੂੰ ਦਿਖਾਓਗੇ?',
        _ => 'Which craft will you show the world today?',
      };

  String get framePrompt => languageCode == 'hi' ? 'अपनी कला को फ्रेम में रखें' : 'Keep your craft inside the frame';
  String get scanCraft => languageCode == 'hi' ? 'कला स्कैन करें' : 'Scan your craft';
  String get cameraHint => languageCode == 'hi' ? 'तस्वीर लें • AI मदद करेगा' : 'Take a photo • AI will help';
  String get gallery => languageCode == 'hi' ? 'गैलरी से चुनें' : 'Choose from gallery';
  String get myArt => languageCode == 'hi' ? 'मेरी कला' : 'My Art';
  String get orders => languageCode == 'hi' ? 'ऑर्डर' : 'Orders';
  String get earnings => languageCode == 'hi' ? 'पैसा' : 'Earnings';
  String get learn => languageCode == 'hi' ? 'सीखें' : 'Learn';
  String get speakHelp => languageCode == 'hi' ? 'माइक दबाकर सहायता लें' : 'Tap the mic for help';
  String get speakPrice => languageCode == 'hi' ? 'कीमत बदलने के लिए बोलें' : 'Say a command to edit your listing';
}
