/// Constants and symbols for Bengali numerals and traditional Land Survey notations
class BanglaNumerals {
  BanglaNumerals._();

  static const List<String> englishDigits = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
  ];

  static const List<String> banglaDigits = [
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'
  ];

  /// Convert any number or string with ASCII digits to Bengali digits
  static String toBangla(dynamic value) {
    if (value == null) return '';
    String text = value.toString();
    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(englishDigits[i], banglaDigits[i]);
    }
    return text;
  }

  /// Convert Bengali digits in a string to English/ASCII digits
  static String toEnglish(String text) {
    String res = text;
    for (int i = 0; i < 10; i++) {
      res = res.replaceAll(banglaDigits[i], englishDigits[i]);
    }
    return res;
  }

  /// Traditional Bengali Khatian Ana Symbols (আনা প্রতীক)
  /// ১ আনা = ৵ বা ।
  /// ২ আনা = ৶ বা ॥
  /// ৩ আনা = ৸ বা ৩/
  /// ৪ আনা = ৲ বা /
  /// ৫ আনা = /৵
  /// ১৬ আনা = ১ (বা সম্পূর্ণ হিস্যা)
  static const Map<int, String> anaSymbols = {
    0: '০',
    1: '৵', // 1 Ana
    2: '৶', // 2 Ana
    3: '৸', // 3 Ana
    4: '৲', // 4 Ana (or /)
    5: '৲৵', // 5 Ana
    6: '৲৶', // 6 Ana
    7: '৲৸', // 7 Ana
    8: '॥', // 8 Ana
    9: '॥৵', // 9 Ana
    10: '॥৶', // 10 Ana
    11: '॥৸', // 11 Ana
    12: '৲॥', // 12 Ana
    13: '৲॥৵', // 13 Ana
    14: '৲॥৶', // 14 Ana
    15: '৲॥৸', // 15 Ana
    16: '১ (ষোল আনা)', // 16 Ana (Full)
  };

  /// Traditional Kora Symbols (কড়া সংকেত)
  static const Map<int, String> koraSymbols = {
    0: '০',
    1: '।', // 1 Kora
    2: '॥', // 2 Kora
    3: '৶', // 3 Kora
  };

  /// Traditional Kranti Symbols (ক্রান্তি সংকেত)
  static const Map<int, String> krantiSymbols = {
    0: '০',
    1: '∠', // 1 Kranti (single slant mark)
    2: '∠∠', // 2 Kranti (double slant mark)
  };
}
