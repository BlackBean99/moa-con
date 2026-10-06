#!/usr/bin/env python3
import plistlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
from advertising_config import TEST_APP_ID, activation_checks, load_metadata
metadata = load_metadata()
ads = metadata.get('ads', {})
if ads.get('enabled') is True:
    blockers = [reason for passed, reason in activation_checks(metadata) if not passed]
    if blockers:
        raise SystemExit('Cannot enable live advertising: ' + '; '.join(blockers))
path = ROOT / 'GifticonCollector/Resources/Info.plist'
info = plistlib.loads(path.read_bytes())
for key, field in [('MoaconOperatorName', 'operatorName'), ('MoaconSupportEmail', 'supportEmail'),
                   ('MoaconPrivacyPolicyURL', 'privacyPolicyURL'), ('MoaconSupportURL', 'supportURL')]:
    info[key] = metadata[field]
info['CFBundleShortVersionString'] = metadata['version']
info['CFBundleVersion'] = metadata['build']
info['ITSAppUsesNonExemptEncryption'] = False
info['GADApplicationIdentifier'] = ads.get('appID') if ads.get('enabled') is True else TEST_APP_ID
info['GADDelayAppMeasurementInit'] = True
for key, field in [('MoaconAdsEnabled', 'enabled'), ('MoaconAdsConsentConfigured', 'consentConfigured'),
                   ('MoaconAdsPrivacyReviewed', 'privacyDisclosureReviewed'), ('MoaconAdsAppAdsTxtVerified', 'appAdsTxtVerified'),
                   ('MoaconAdsReadinessApproved', 'appReadinessApproved')]:
    info[key] = ads.get(field) is True
info['MoaconBannerAdUnitID'] = ads.get('bannerUnitID', '') if ads.get('enabled') is True else ''
path.write_bytes(plistlib.dumps(info, sort_keys=False))
# Keep extension, app and metadata build numbers together.
extension = ROOT / 'GifticonCollectorShare/Info.plist'
ext_info = plistlib.loads(extension.read_bytes())
ext_info['CFBundleShortVersionString'] = metadata['version']
ext_info['CFBundleVersion'] = metadata['build']
extension.write_bytes(plistlib.dumps(ext_info, sort_keys=False))
print('App metadata updated; empty operator/URL fields still block submission.')
