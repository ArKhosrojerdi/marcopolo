#!/usr/bin/env python3
"""Join flag-icons + mledoze/countries into assets/data/countries.json.

Output row schema (only fields the app needs):
  { code, fa, en, capital, currencyName, currencySymbol, region }

- code: lowercase ISO-3166-1 alpha-2 (matches flag SVG filename)
- fa:   Persian common name (mledoze translations.per.common)
- en:   English common name
- capital: first capital (English; Persian unavailable in source)
- currencyName / currencySymbol: first currency
- region: Persian bucket -> آسیا / اروپا / آفریقا / آمریکا / سایر
"""
import json, os, shutil, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLAG_ICONS = os.path.expanduser("~/Downloads/flag-icons-main")
MLEDOZE = os.path.join(ROOT, "tool", "mledoze_countries.json")
MLEDOZE_URL = "https://raw.githubusercontent.com/mledoze/countries/master/dist/countries.json"
OUT_DATA = os.path.join(ROOT, "assets", "data", "countries.json")
OUT_FLAGS = os.path.join(ROOT, "assets", "flags", "4x3")

REGION_FA = {
    "Asia": "آسیا",
    "Europe": "اروپا",
    "Africa": "آفریقا",
    "Americas": "آمریکا",
}

def main():
    if not os.path.exists(MLEDOZE):
        print(f"fetching {MLEDOZE_URL}")
        urllib.request.urlretrieve(MLEDOZE_URL, MLEDOZE)
    mledoze = json.load(open(MLEDOZE, encoding="utf-8"))
    flag_country = json.load(open(os.path.join(FLAG_ICONS, "country.json"), encoding="utf-8"))
    have_flag = {c["code"].lower() for c in flag_country}

    rows = []
    skipped = []
    for c in mledoze:
        code = c.get("cca2", "").lower()
        if not code or code not in have_flag:
            skipped.append(code)
            continue
        region = c.get("region", "")
        fa = c.get("translations", {}).get("per", {}).get("common")
        en = c.get("name", {}).get("common", "")
        if not fa:
            fa = en  # fall back to English if no Persian translation
        cap = c.get("capital") or []
        capital = cap[0] if cap else ""
        cur_name = cur_sym = ""
        currencies = c.get("currencies") or {}
        if currencies:
            first = next(iter(currencies.values()))
            cur_name = first.get("name", "")
            cur_sym = first.get("symbol", "")
        rows.append({
            "code": code,
            "fa": fa,
            "en": en,
            "capital": capital,
            "currencyName": cur_name,
            "currencySymbol": cur_sym,
            "region": REGION_FA.get(region, "سایر"),
        })

    rows.sort(key=lambda r: r["en"])
    os.makedirs(os.path.dirname(OUT_DATA), exist_ok=True)
    json.dump(rows, open(OUT_DATA, "w", encoding="utf-8"), ensure_ascii=False, indent=0)

    # copy only the flag SVGs we actually reference
    os.makedirs(OUT_FLAGS, exist_ok=True)
    copied = 0
    for r in rows:
        src = os.path.join(FLAG_ICONS, "flags", "4x3", r["code"] + ".svg")
        if os.path.exists(src):
            shutil.copy(src, os.path.join(OUT_FLAGS, r["code"] + ".svg"))
            copied += 1

    by_region = {}
    for r in rows:
        by_region[r["region"]] = by_region.get(r["region"], 0) + 1
    print(f"rows={len(rows)} flags_copied={copied}")
    print("by_region:", by_region)
    print("missing_currency:", sum(1 for r in rows if not r["currencyName"]))
    print("missing_capital:", sum(1 for r in rows if not r["capital"]))

if __name__ == "__main__":
    main()
