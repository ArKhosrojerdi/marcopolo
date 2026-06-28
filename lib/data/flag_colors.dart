/// STUB flag-color data. The real feature (normal-difficulty flag levels asking
/// "which country has a given color in its flag?") needs every country tagged with the
/// colors present in its flag. That data is not in countries.json yet.
///
/// This file is a deliberately small, hand-checked placeholder so the
/// [LevelKind.color] generator and its UI can be built and demoed end-to-end.
/// Replace [kFlagColors] with full coverage (ideally generated into the dataset)
/// before shipping color levels for real.
library;

/// The colors a color-level can ask about.
enum FlagColor { red, blue, white, green, yellow, black }

extension FlagColorFa on FlagColor {
  String get fa => switch (this) {
        FlagColor.red => 'قرمز',
        FlagColor.blue => 'آبی',
        FlagColor.white => 'سفید',
        FlagColor.green => 'سبز',
        FlagColor.yellow => 'زرد',
        FlagColor.black => 'مشکی',
      };
}

/// Country code → colors in its flag. PLACEHOLDER subset — not exhaustive.
const Map<String, Set<FlagColor>> kFlagColors = {
  'ir': {FlagColor.green, FlagColor.white, FlagColor.red},
  'fr': {FlagColor.blue, FlagColor.white, FlagColor.red},
  'de': {FlagColor.black, FlagColor.red, FlagColor.yellow},
  'it': {FlagColor.green, FlagColor.white, FlagColor.red},
  'jp': {FlagColor.white, FlagColor.red},
  'br': {FlagColor.green, FlagColor.yellow, FlagColor.blue, FlagColor.white},
  'sa': {FlagColor.green, FlagColor.white},
  'ca': {FlagColor.red, FlagColor.white},
  'in': {FlagColor.green, FlagColor.white},
  'za': {
    FlagColor.green,
    FlagColor.white,
    FlagColor.red,
    FlagColor.blue,
    FlagColor.yellow,
    FlagColor.black,
  },
  'eg': {FlagColor.red, FlagColor.white, FlagColor.black},
  'se': {FlagColor.blue, FlagColor.yellow},
  'gr': {FlagColor.blue, FlagColor.white},
  'tr': {FlagColor.red, FlagColor.white},
  'ng': {FlagColor.green, FlagColor.white},
  'ar': {FlagColor.blue, FlagColor.white, FlagColor.yellow},
  'au': {FlagColor.blue, FlagColor.white, FlagColor.red},
  'es': {FlagColor.red, FlagColor.yellow},
  'pt': {FlagColor.green, FlagColor.red, FlagColor.yellow},
  'ru': {FlagColor.white, FlagColor.blue, FlagColor.red},
};

/// Countries we have color data for (the only pool a color question may draw on).
Iterable<String> get kFlagColorCodes => kFlagColors.keys;

bool flagHasColor(String code, FlagColor color) =>
    kFlagColors[code]?.contains(color) ?? false;
