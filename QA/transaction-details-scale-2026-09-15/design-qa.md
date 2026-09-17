# Transaction details — visual QA

Reference: `3-Вставленное-изображение-3.jpg`, 590 × 1280 px.

## Geometry matched

- Header bottom: approximately 151 px.
- Tabs bottom: approximately 235 px.
- Tabs: three-column grid; `Details` and `Tracker` occupy the first two columns.
- Summary bottom: approximately 441 px.
- Details start: approximately 468 px.
- Detail field pitch: approximately 77–79 px.
- Beneficiary name and amount were reduced to the reference scale.

## Runtime verification

- Debug build: passed on iPhone 17 Pro simulator.
- Direct QA route: `transaction-details` opened successfully.
- Scrollable details and receipt controls remain present.
- All transaction values continue to come from `CompletedTransfer`.

## Artifacts

- `transaction-details-final-590x1280.png` — final runtime screen normalized to the reference size.
- `reference-final-overlay-50.png` — 50% reference/runtime overlay.

## Remaining reference-dependent differences

- Status-bar geometry differs between the reference device and iPhone 17 Pro Dynamic Island.
- Text content differs because the runtime screen deliberately uses the saved transaction rather than hardcoded reference values.
