#!/usr/bin/env python3
"""Read-only ad revenue activation gate, with optional real-publisher app-ads.txt generation."""
import argparse
from advertising_config import ROOT, activation_checks, app_ads_txt, load_metadata

parser = argparse.ArgumentParser()
parser.add_argument('--strict', action='store_true')
parser.add_argument('--write-app-ads-txt', action='store_true')
args = parser.parse_args()
metadata = load_metadata()
failures = 0
for passed, reason in activation_checks(metadata):
    print(('PASS ' if passed else 'BLOCK ') + reason)
    failures += not passed
print(f'{failures} ad-revenue prerequisites outstanding. Release advertising enabled: {metadata.get("ads", {}).get("enabled", False)}')
if args.write_app_ads_txt:
    try:
        value = app_ads_txt(metadata)
    except ValueError as error:
        parser.error(str(error))
    directory = ROOT / 'artifacts/release/admob'
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / 'app-ads.txt'
    target.write_text(value)
    print(f'Generated {target}; host at the root of the developer website, then verify in AdMob. No hosting performed.')
raise SystemExit(1 if args.strict and failures else 0)
