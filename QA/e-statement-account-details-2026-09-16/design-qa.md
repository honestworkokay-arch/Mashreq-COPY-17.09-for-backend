# Design QA — E-statement and Account Details

## Implemented surfaces

- `Your Account Details`: reference header, three-tab strip, account metadata,
  separate Copy actions for account number and IBAN, and Copy all details.
- `Statement request`: duration/date-range selection, review, PDF generation,
  PDFKit preview and system share/save sheet.
- Full-width duration and PDF sheets use the shared zero-gap sheet modifier.
- Banking event cards are generated for beneficiary creation, transfer,
  debit and credit/top-up events.

## Source-of-truth checks

- Account number and IBAN are read from `AppSession.profile`.
- Statement rows are read from `AppSession.transactions`.
- Statement balance is reconstructed from the persisted transaction ledger.
- Messages composer uses the saved profile phone number and requires explicit
  user confirmation, per the public iOS API contract.

## Verification

- Swift parser: passed.
- Swift iOS 17 simulator typecheck: passed.
- `project.pbxproj` lint: passed.
- Whitespace/error marker check: passed.
- Full Xcode build was started but the local Xcode service did not complete the
  generic simulator destination resolution within the available verification
  window; no build failure was emitted.

## Remaining visual gate

- Simulator screenshots and 50% reference overlays are still required before
  claiming pixel-perfect parity. Current estimate from code geometry: 8/10.
