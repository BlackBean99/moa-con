# App Review notes draft

Moacon is a local coupon wallet. No account, sign-in, subscription, in-app purchase or backend is required. The release build starts with an empty wallet. Test fixtures are only included in the Debug UI-test build and are not shipped in Release.

1. Tap 시작하기 (Start) once. No permission prompt is shown here.
2. Tap + / 사진 추가 (Add photo), then 사진 한 장 선택 (Select one photo). Select an attached **non-redeemable sample** coupon image. Full photo-library access is not required for this picker.
3. In 쿠폰 등록 (Register coupon), check brand, product, barcode and expiration date. For a multiple-code image, select the intended barcode. If recognition fails, fill the fields manually. Tap 보관 (Save).
4. Open the coupon and tap 원본 크게 보기 (View original) to zoom the stored image. Tap 사용 완료 (Mark used); 사용 취소 reverses the manual usage status.
5. In 수정 (Edit), select 상품 교환권 (Product voucher) or 금액권 (Stored-value voucher). Only stored-value vouchers expose balance deduction. Usage status and balances are manual records, not issuer redemption verification.
6. To test expiration notifications, use a future expiration date and open … → 알림 설정 (Notification settings). Turn on 만료 알림 and allow the OS permission. Only confirmed unused coupons are scheduled. The settings display the pending count. Turning the setting off removes pending expiration notifications.
7. Share an image from Photos via the system share sheet → 모아콘. The extension displays saved/failed counts. Open the app to import. Images without usable barcodes remain in … → 가져오기 대기 (Pending imports), where retry, manual input and delete are available.
8. … → 개인정보 처리 shows local data handling. Public privacy/support URLs and contact information must be supplied before submission.

Vision analysis runs on-device. Photo copies and coupon metadata are stored locally. The app has no advertising/tracking/analytics SDK. Automatic library scanning requires optional photo permission; choosing a photo or sharing it does not request full library access.

Review attachments: fixtures/single-code.png, fixtures/multiple-codes.png and fixtures/no-code.png. Each is visibly marked 테스트 쿠폰 · 사용 불가 and contains only an invalid MOACON-TEST identifier. Generate them with swift scripts/generate-review-fixtures.swift. These are input images, not App Store screenshots. Contact fields are in metadata.json and are not yet filled.
