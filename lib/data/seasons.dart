import '../theme/app_theme.dart' show toPersianDigits;
import 'quiz_repository.dart';

/// A single level inside a season. A level is a finite quiz: [questionCount]
/// questions drawn from [mode]/[region], played with a fixed number of lives.
///
/// Level kinds beyond plain name-recall (flag colors, symbols, blank-typing,
/// capital-by-flag, etc.) are intentionally not modelled yet — they need flag
/// attribute data the dataset does not carry. New [LevelKind]s slot in here
/// once that data exists, without touching the season/progress machinery.
enum LevelKind { name, color }

class LevelDef {
  const LevelDef({
    required this.globalIndex,
    required this.mode,
    this.region,
    this.kind = LevelKind.name,
    this.questionCount = 10,
  });

  /// 1-based index across the whole catalog — also the persistence key and the
  /// unlock order. Level N unlocks once level N-1 has been played once.
  final int globalIndex;
  final GameMode mode;
  final String? region;
  final LevelKind kind;
  final int questionCount;

  /// Label shown on the level tile ("۱", "۲", …) is derived from the season's
  /// local position; this is the human title for the play screen header.
  String get titleFa => 'مرحله ${toPersianDigits(globalIndex)}';
}

class SeasonDef {
  const SeasonDef({
    required this.id,
    required this.titleFa,
    required this.emoji,
    required this.levels,
  });

  final String id;
  final String titleFa;
  final String emoji;
  final List<LevelDef> levels;

  int get firstGlobalIndex => levels.first.globalIndex;
  int get lastGlobalIndex => levels.last.globalIndex;
}

/// The static season catalog. This first cut ships two seasons built entirely
/// from data already in the dataset (flag-by-name and capital-by-name). The
/// per-region progression mirrors the flag game mode (Europe → Asia → Americas
/// → Africa → Other → whole world), getting wider as it goes.
class SeasonCatalog {
  SeasonCatalog._();

  static final List<SeasonDef> seasons = _build();

  /// Flat view of every level across all seasons, indexed by [globalIndex]-1.
  static final List<LevelDef> allLevels = [
    for (final s in seasons) ...s.levels,
  ];

  static int get totalLevels => allLevels.length;

  static List<SeasonDef> _build() {
    var g = 0;
    LevelDef mk(
      GameMode mode,
      String? region,
      int count, {
      LevelKind kind = LevelKind.name,
    }) => LevelDef(
      globalIndex: ++g,
      mode: mode,
      region: region,
      questionCount: count,
      kind: kind,
    );

    // Flag season: 15 levels per named region + 20 world levels, then a demo
    // color level. Question count ramps gently within each block.
    final flagLevels = <LevelDef>[];
    const regionList = <String?>['اروپا', 'آسیا', 'آمریکا', 'آفریقا', 'سایر'];
    for (final region in regionList) {
      for (var i = 0; i < 15; i++) {
        flagLevels.add(mk(GameMode.flag, region, 8 + (i ~/ 5) * 2));
      }
    }
    // 20 world (all-regions) levels
    for (var i = 0; i < 25; i++) {
      flagLevels.add(mk(GameMode.flag, null, 8 + (i ~/ 5) * 2));
    }
    flagLevels.add(mk(GameMode.flag, null, 8, kind: LevelKind.color));

    // Capital season: 12 world levels, ramping question count.
    final capitalLevels = <LevelDef>[
      for (var i = 0; i < 12; i++) mk(GameMode.capital, null, 8 + (i ~/ 3) * 2),
    ];

    return [
      SeasonDef(
        id: 'flags',
        titleFa: 'فصل پرچم‌ها',
        emoji: '🚩',
        levels: flagLevels,
      ),
      SeasonDef(
        id: 'capitals',
        titleFa: 'فصل پایتخت‌ها',
        emoji: '🏛️',
        levels: capitalLevels,
      ),
    ];
  }
}
