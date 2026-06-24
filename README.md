# مارکوپولو — Persian Country Quiz

Offline, RTL Persian country-quiz game built in Flutter (web + Android + iOS).
Implemented from the `Country Quiz Wireframes.dc.html` handoff (paper / hand-drawn look).

## Game modes

- **پرچم (Flag)** — guess the country from its flag. Has a continent-select step
  (کل جهان / آسیا / اروپا / آفریقا / آمریکا).
- **واحد پول (Currency)** — guess the country from its currency symbol + name.
- **پایتخت (Capital)** — guess a country's capital city.
- **نقشه کشور (Map)** — stubbed ("به‌زودی") until a border-outline SVG source is added.

Endless mode: each correct answer raises the streak record (رکورد); a wrong answer
resets the streak to 0. The record persists across runs via `shared_preferences`.

## Run

```bash
flutter pub get
flutter run -d chrome      # web
flutter run -d <android>   # native
flutter test               # logic + flow tests
```

> iOS simulator builds fail at `actool` on this machine — verify on Android/web.

## Data

`assets/data/countries.json` + `assets/flags/4x3/*.svg` are **generated**, not hand-written.
`tool/build_data.py` joins two open datasets:

1. **flag-icons** (`~/Downloads/flag-icons-main`) — flag SVGs + `country.json`.
2. **mledoze/countries** (`dist/countries.json`, auto-fetched & cached in `tool/`) —
   Persian names (`translations.per`), capitals, currencies, regions, keyed by `cca2`.

Regenerate:

```bash
python3 tool/build_data.py
```

### Known limitations

- Capital cities and currency names are English where Persian is unavailable in the
  source datasets; **flag** mode is fully Persian.
- Oceania / Antarctic countries appear only under "کل جهان".
- Map mode pending a country-border SVG source.
