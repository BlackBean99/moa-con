#!/usr/bin/env python3
"""Read-only submission gate; never uploads or submits an app."""
import argparse
import plistlib
import re
import subprocess
import struct
from pathlib import Path
from urllib.parse import urlparse
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(); p.add_argument('--strict', action='store_true'); args = p.parse_args()
from advertising_config import activation_checks, load_metadata
metadata = load_metadata()
info = plistlib.loads((ROOT / 'GifticonCollector/Resources/Info.plist').read_bytes())
manifest = plistlib.loads((ROOT / 'GifticonCollector/Resources/PrivacyInfo.xcprivacy').read_bytes())
failures = []
def require(condition, reason):
    print(('PASS ' if condition else 'BLOCK ') + reason)
    if not condition: failures.append(reason)
require(info['CFBundleShortVersionString'] == metadata['version'] and info['CFBundleVersion'] == metadata['build'], 'App version matches release metadata')
require(not manifest['NSPrivacyTracking'] and bool(manifest['NSPrivacyAccessedAPITypes']), 'App-owned privacy manifest present (SDK manifests need separate review)')
require(metadata.get('ads', {}).get('privacyDisclosureReviewed') is True,
        'Bundled Google Ads/UMP privacy report reviewed even if advertising is disabled')
require(info.get('MoaconAdsEnabled') == (metadata.get('ads', {}).get('enabled') is True), 'App advertising mode matches metadata')
if metadata.get('ads', {}).get('enabled') is True:
    for passed, reason in activation_checks(metadata): require(passed, reason)
    require(info.get('GADApplicationIdentifier') == metadata['ads']['appID'] and
            info.get('MoaconBannerAdUnitID') == metadata['ads']['bannerUnitID'], 'Live ad identifiers applied to app')
for field in ['operatorName', 'supportEmail', 'reviewContactName', 'reviewContactEmail', 'reviewContactPhone']:
    require(bool(metadata[field].strip()), field + ' configured')
for field, key in [('privacyPolicyURL', 'MoaconPrivacyPolicyURL'), ('supportURL', 'MoaconSupportURL')]:
    value = metadata[field]
    require(urlparse(value).scheme == 'https' and bool(urlparse(value).netloc) and info.get(key) == value, field + ' configured in app')
for field in ['appStoreConnectRecordVerified', 'distributionValidated', 'ageRatingQuestionnaireCompleted', 'appPrivacyCompleted']:
    require(metadata[field] is True, field)
for device, sizes in {'iPhone': {(1260, 2736), (1290, 2796), (1320, 2868), (1284, 2778), (1242, 2688)}, 'iPad': {(2064, 2752), (2048, 2732)}}.items():
    paths = metadata.get('screenshots', {}).get(device, [])
    valid = bool(paths)
    for path in paths:
        target = (ROOT / path).resolve()
        if not target.is_relative_to(ROOT) or not target.is_file():
            valid = False; continue
        data = target.read_bytes()
        valid = valid and data[:8] == b'\x89PNG\r\n\x1a\n' and len(data) >= 33
        if len(data) >= 33:
            width, height = struct.unpack('>II', data[16:24])
            valid = valid and ((width, height) in sizes or (height, width) in sizes) and data[25] in (0, 2, 3)
            valid = valid and b'tRNS' not in data
    require(valid, device + ' store screenshots present at supported dimensions without transparency')
require(all((ROOT / 'docs/release/fixtures' / (name + '.png')).is_file() for name in ['single-code', 'multiple-codes', 'no-code']), 'Non-redeemable review input fixtures present')
result = subprocess.run(['python3', str(ROOT / 'scripts/tasks.py'), 'check'], capture_output=True, text=True)
require(result.returncode == 0, 'Task tracker valid')
todo = (ROOT / 'tasks/todo.md').read_text()
for task in ['T09', 'T10', 'T11']:
    block = re.search(rf'^## {task}:.*?(?=^## |\Z)', todo, flags=re.M | re.S).group()
    require('**Status:** done' in block, task + ' verification completed')
print(f'{len(failures)} submission blockers. No upload performed.')
raise SystemExit(1 if args.strict and failures else 0)
