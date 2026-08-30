# Transfer finalization checkpoint — 2026-08-30

Temporary operational checkpoint. Do not treat transport chunks as final deliverables and do not delete them until reconstructed outputs are independently verified.

## Google Drive state

### School / old Yandex share

All four source videos are fully represented on Google Drive as exact byte-range parts:

- `выпускной клип.mp4`: 13 parts, exact source size `1,241,060,815` bytes, source SHA256 `0fcadc1b53c6f90c16fe7125a07014a9e15fad0281d8c63f4b7f218c255f39cd`.
- `Последний звонок клип.mp4`: 16 parts, exact source size `1,528,082,371` bytes, source SHA256 `5594451b481999b9ff8e2e656a937d48a603ae1d65148acd2f2fb30ab7ac27cd`.
- `Последний звонок.mp4`: 51 parts, exact source size `5,053,962,886` bytes, source SHA256 `12c31327edf92c6d0489b97738807d73fc696c7ad558edc1dedf624841f82856`.
- `выпускной.mp4`: 113 parts, exact source size `11,294,518,113` bytes, source SHA256 `628bdd80894cd8296838d2011d0ed0f2ab4a3912629fec35eabe9bcabaf40ed`.

Old-Yandex total: `19,117,624,185` bytes.

`выпускной.mp4` was audited as parts `001..113`; parts 001..112 are 100,000,000 bytes each and part113 is 94,518,113 bytes.

A local reconstruction of `Последний звонок клип.mp4` was already byte-concatenated and its SHA256 matched the source SHA above exactly. Current Library->Drive uploader rejects files >512 MiB, so transport parts MUST remain until a large-file upload route is available.

### Wfolio SOHO 30.06.2026

Original archive:
- exact archive size `5,584,535,044` bytes
- 877 source JPEG files
- 56 transport parts are all present on Drive
- reconstructed ZIP passed Python `ZipFile.testzip()` with no CRC error before local duplicate parts were deleted

Normal-file restoration progress: archive-order entries **1..422 of 877** are now present as ordinary JPEG files in the Drive Wfolio folder. The next not-yet-uploaded archive entry is entry 423 (`5J3B9094.jpg`).

The Files/Library Drive upload channel hit its explicit file-upload quota immediately after successfully uploading entry 422 (`5J3B9092.jpg`) and returned `Повторите попытку через 2 часа` for subsequent writes. Do not retry-delete or overwrite existing JPEGs; destination conflicts mean the file is already present.

### New Yandex June 30 photos

Source inventory is fully safe on Drive in independent ZIP_STORED packs:
- `/ВСЕ`: 931 JPEG, 6,912,860,320 source bytes, 81/81 ZIP packs
- `/ИНДИВИДУАЛЬНЫЕ 1`: 403 JPEG, 2,902,530,815 source bytes, 34/34 ZIP packs
- total: 1334 JPEG, 9,815,391,135 source bytes

The packs preserve original JPEG bytes (`ZIP_STORED`). Final presentation should extract them to normal JPEG files; keep packs until count/size verification succeeds.

## Finalization policy

1. Never delete a `.partNNN` video/archive chunk until the reconstructed output has exact expected byte size and integrity verification.
2. Video reconstruction is raw byte concatenation in numeric part order, not transcoding/remuxing.
3. Verify each reconstructed MP4 against the source SHA256 listed above.
4. Wfolio: either preserve the exact reconstructed ZIP or, preferably for human usability, restore all 877 JPEGs as ordinary files; 56 archive parts stay until completion is verified.
5. New-Yandex photo ZIP packs are not concatenated. Extract each independent pack and verify final counts 931 + 403 = 1334.
6. Only after all final outputs are verified may temporary part folders, ZIP-pack folders, test files, helper branches/workflows/releases/issues be removed.

## Current blockers

- Direct Google Drive connector is disabled server-side in this session.
- Files/Library Google Drive uploader works but has a 512 MiB per-file ceiling and, at this checkpoint, an explicit temporary file-upload quota cooldown.
- Therefore no video transport chunks have been deleted.

## Resume point

- Wfolio: resume ordinary JPEG uploads at archive entry 423 (`5J3B9094.jpg`), then continue through 877.
- After Wfolio, restore all 1334 Yandex JPEGs from the 115 independent ZIP packs.
- Continue searching for a Drive large-file upload route for the four reconstructed MP4 files; do not sacrifice the verified chunks while doing so.
