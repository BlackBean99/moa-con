"""Shared, offline AdMob configuration validation. IDs are public identifiers, never credentials."""
import json
import re
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
TEST_APP_ID = 'ca-app-pub-3940256099942544~1458002511'

def load_metadata():
    metadata = json.loads((ROOT / 'docs/release/metadata.json').read_text())
    local = ROOT / 'docs/release/metadata.local.json'
    if local.exists():
        overrides = json.loads(local.read_text())
        metadata['ads'] = {**metadata.get('ads', {}), **overrides.get('ads', {})}
        metadata.update({key: value for key, value in overrides.items() if key != 'ads'})
    return metadata

def public_https(value):
    parsed = urlparse(value)
    return parsed.scheme == 'https' and bool(parsed.hostname) and not parsed.username and not parsed.password

def activation_checks(metadata):
    ads = metadata.get('ads', {})
    app = ads.get('appID', '')
    banner = ads.get('bannerUnitID', '')
    publisher = ads.get('publisherID', '')
    real = lambda value: '3940256099942544' not in value
    app_ok = bool(re.fullmatch(r'ca-app-pub-[0-9]{16}~[0-9]{10}', app)) and real(app)
    banner_ok = bool(re.fullmatch(r'ca-app-pub-[0-9]{16}/[0-9]{10}', banner)) and real(banner)
    publisher_ok = bool(re.fullmatch(r'pub-[0-9]{16}', publisher)) and real(publisher)
    return [
        (app_ok, 'Actual iOS AdMob app ID (not a Google sample)'),
        (banner_ok, 'Actual wallet banner unit ID (not a Google sample)'),
        (publisher_ok and app_ok and banner_ok and app.split('~')[0] == banner.split('/')[0] == 'ca-app-' + publisher,
         'App, banner and app-ads.txt belong to the same publisher'),
        (public_https(metadata.get('privacyPolicyURL', '')), 'Public HTTPS privacy policy'),
        (public_https(ads.get('developerWebsiteURL', '')), 'Developer website in Store listing'),
        (ads.get('consentConfigured') is True, 'AdMob UMP messages configured and real-account flows tested'),
        (ads.get('privacyDisclosureReviewed') is True and metadata.get('appPrivacyCompleted') is True,
         'App Privacy and SDK report reviewed for the actual ad mode'),
        (ads.get('appAdsTxtVerified') is True, 'Hosted app-ads.txt verified in AdMob'),
        (ads.get('appReadinessApproved') is True, 'Store app linked and AdMob readiness approved'),
        (ads.get('paymentAccountReady') is True, 'Publisher account and payment setup confirmed'),
    ]

def app_ads_txt(metadata):
    publisher = metadata.get('ads', {}).get('publisherID', '')
    if not re.fullmatch(r'pub-[0-9]{16}', publisher) or '3940256099942544' in publisher:
        raise ValueError('A real publisher ID is required; no placeholder file will be generated.')
    return f'google.com, {publisher}, DIRECT, f08c47fec0942fa0\n'
