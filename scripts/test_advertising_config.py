#!/usr/bin/env python3
"""Counterexamples for live ad activation; independent of SDK/UI behavior."""
import copy
import unittest
from advertising_config import activation_checks, app_ads_txt

class AdvertisingConfigTests(unittest.TestCase):
    def setUp(self):
        self.metadata = {'privacyPolicyURL': 'https://example.com/privacy', 'appPrivacyCompleted': True,
                         'ads': {'appID': 'ca-app-pub-1234567890123456~1234567890',
                                 'bannerUnitID': 'ca-app-pub-1234567890123456/1234567890',
                                 'publisherID': 'pub-1234567890123456', 'developerWebsiteURL': 'https://example.com',
                                 'consentConfigured': True, 'privacyDisclosureReviewed': True,
                                 'appAdsTxtVerified': True, 'appReadinessApproved': True, 'paymentAccountReady': True}}
    def test_valid_configuration_and_real_publisher_file(self):
        self.assertTrue(all(ok for ok, _ in activation_checks(self.metadata)))
        self.assertEqual(app_ads_txt(self.metadata), 'google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0\n')
    def test_every_missing_approval_blocks_activation(self):
        for key in ['consentConfigured', 'privacyDisclosureReviewed', 'appAdsTxtVerified', 'appReadinessApproved', 'paymentAccountReady']:
            with self.subTest(key=key):
                altered = copy.deepcopy(self.metadata); altered['ads'][key] = False
                self.assertFalse(all(ok for ok, _ in activation_checks(altered)))
    def test_sample_or_mismatched_ids_and_insecure_policy_block(self):
        for key, value in [('appID', 'ca-app-pub-3940256099942544~1458002511'),
                           ('bannerUnitID', 'ca-app-pub-9999999999999999/1234567890'), ('publisherID', 'pub-9999999999999999')]:
            altered = copy.deepcopy(self.metadata); altered['ads'][key] = value
            self.assertFalse(all(ok for ok, _ in activation_checks(altered)))
        self.metadata['privacyPolicyURL'] = 'http://example.com/privacy'
        self.assertFalse(all(ok for ok, _ in activation_checks(self.metadata)))
    def test_no_fake_app_ads_txt_is_generated(self):
        for value in ['', 'pub-3940256099942544', 'pub-invalid']:
            self.metadata['ads']['publisherID'] = value
            with self.assertRaises(ValueError): app_ads_txt(self.metadata)

if __name__ == '__main__': unittest.main()
