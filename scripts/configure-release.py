#!/usr/bin/env python3
import json
import plistlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
metadata = json.loads((ROOT / 'docs/release/metadata.json').read_text())
local_metadata = ROOT / 'docs/release/metadata.local.json'
if local_metadata.exists(): metadata.update(json.loads(local_metadata.read_text()))
path = ROOT / 'GifticonCollector/Resources/Info.plist'
info = plistlib.loads(path.read_bytes())
for key, field in [('MoaconOperatorName', 'operatorName'), ('MoaconSupportEmail', 'supportEmail'),
                   ('MoaconPrivacyPolicyURL', 'privacyPolicyURL'), ('MoaconSupportURL', 'supportURL')]:
    info[key] = metadata[field]
info['CFBundleShortVersionString'] = metadata['version']
info['CFBundleVersion'] = metadata['build']
info['ITSAppUsesNonExemptEncryption'] = False
path.write_bytes(plistlib.dumps(info, sort_keys=False))
print('App metadata updated; empty operator/URL fields still block submission.')
