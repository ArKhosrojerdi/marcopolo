import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import 'map_codes.dart';

/// One country row, loaded from assets/data/countries.json.
class Country {
  final String code; // lowercase ISO alpha-2 (matches flag svg filename)
  final String fa; // Persian common name
  final String en; // English common name
  final String capital; // English (Persian unavailable in source)
  final String currencyName;
  final String currencyFa;
  final String currencySymbol;
  final String region; // Persian bucket: آسیا/اروپا/آفریقا/آمریکا/سایر
  final List<String> borders; // codes of neighboring countries (alpha-2)

  const Country({
    required this.code,
    required this.fa,
    required this.en,
    required this.capital,
    required this.currencyName,
    required this.currencyFa,
    required this.currencySymbol,
    required this.region,
    this.borders = const [],
  });

  factory Country.fromJson(Map<String, dynamic> j) => Country(
        code: j['code'] as String,
        fa: j['fa'] as String,
        en: j['en'] as String,
        capital: j['capital'] as String? ?? '',
        currencyName: j['currencyName'] as String? ?? '',
        currencyFa: j['currencyFa'] as String? ?? '',
        currencySymbol: j['currencySymbol'] as String? ?? '',
        region: j['region'] as String? ?? 'سایر',
        borders: (j['borders'] as List?)?.cast<String>() ?? const [],
      );

  String get flagAsset => 'assets/flags/4x3/$code.svg';
  String get mapAsset => 'assets/maps/$code.svg';
  bool get hasCurrency => currencyName.isNotEmpty;
  bool get hasCapital => capital.isNotEmpty;
  bool get hasMap => kMapCodes.contains(code);
  bool get hasNeighbors => borders.length >= 3;
}

/// Loads and caches the bundled country dataset.
class CountryData {
  CountryData._(this.all);

  /// For tests / custom data sources.
  @visibleForTesting
  CountryData.fromList(this.all);

  final List<Country> all;

  static CountryData? _instance;

  static Future<CountryData> load() async {
    if (_instance != null) return _instance!;
    final raw = await rootBundle.loadString('assets/data/countries.json');
    final list = (json.decode(raw) as List)
        .map((e) => Country.fromJson(e as Map<String, dynamic>))
        .toList();
    _instance = CountryData._(list);
    return _instance!;
  }
}
