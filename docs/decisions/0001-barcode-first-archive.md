# ADR-001: Barcode-first archive and balance tracking

## Status

Accepted

## Context

OCR across an entire photo library is expensive and produces false positives for
ordinary screenshots and photos. GifticonCollector also needs to avoid storing
images that do not contain a usable gifticon barcode, while supporting repeated
use of a gifticon in partial amounts.

## Decision

1. Run a low-resolution Vision barcode pass over the library first.
2. Run Korean OCR only on assets where the barcode pass found a supported barcode.
3. Require a normalized detected barcode before archiving a record.
4. Make `barcodeNumber` unique in SwiftData and return the existing record when a
   duplicate is scanned or manually selected.
5. Store `originalAmount`, `remainingAmount`, and `allowsPartialRedemption`.
   Partial redemption is opt-in and defaults to false. A full-use action remains
   available for every record.

## Consequences

- Most non-gifticon photos avoid the expensive OCR request.
- Text-only gifticon images are intentionally rejected by the archive flow.
- A barcode collision is treated as the same gifticon, even if the source asset
  is different.
- Existing SwiftData stores need lightweight migration testing when the balance
  fields are introduced.
- Real-device measurements remain necessary because barcode detection quality is
  affected by screenshot compression, angle, and image size.
