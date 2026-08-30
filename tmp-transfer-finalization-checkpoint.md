# Transfer finalization checkpoint — 2026-08-30

Temporary operational checkpoint. Transport chunks are NOT final deliverables. Do not delete any sole safe transport copy until the reconstructed output is independently verified.

## School / old Yandex share

All four MP4 sources are fully represented on Google Drive as exact byte-range parts:

- `выпускной клип.mp4`: 13 parts; `1,241,060,815` bytes; SHA256 `0fcadc1b53c6f90c16fe7125a07014a9e15fad0281d8c63f4b7f218c255f39cd`.
- `Последний звонок клип.mp4`: 16 parts; `1,528,082,371` bytes; SHA256 `5594451b481999b9ff8e2e656a937d48a603ae1d65148acd2f2fb30ab7ac27cd`.
- `Последний звонок.mp4`: 51 parts; `5,053,962,886` bytes; SHA256 `12c31327edf92c6d0489b97738807d73fc696c7ad558edc1dedf624841f82856`.
- `выпускной.mp4`: 113 parts; `11,294,518,113` bytes; SHA256 `628bdd80894cd8296838d2011d0ed0f2ab4a3912629fec35eabe9bcabaf40ed`.

Old-Yandex total: `19,117,624,185` bytes.

`выпускной.mp4` was audited as parts `001..113`; parts 001..112 are 100,000,000 bytes and part113 is 94,518,113 bytes.

A local reconstruction of `Последний звонок клип.mp4` was byte-concatenated and matched the source SHA256 exactly. Current Library->Drive uploader rejects files >512 MiB, so video part folders MUST remain until a working large-file upload route is available.

## Wfolio SOHO 30.06.2026

Original archive:
- exact size `5,584,535,044` bytes
- 877 JPEGs
- 56/56 transport parts present on Drive
- reconstructed ZIP previously passed `ZipFile.testzip()` with no CRC error

Ordinary-JPEG restoration has reached **archive entries 1..423 of 877**. Entry 423 is `5J3B9094.jpg` and is confirmed present on Drive. Next unique source entry is entry 424, `5J3B9097.jpg`.

A full Drive listing showed 454 JPEG records for those 423 unique source names: exactly **31 excess duplicate records** were created by an earlier race between two upload streams. The duplicate cleanup set is recorded separately in `tmp-wfolio-duplicate-cleanup.md`. All duplicate pairs/triples have identical file sizes; cleanup must keep one copy of each source name and delete only the documented extras.

Files/Library deletion is not supported for Google Drive items, so duplicate removal is deferred until the direct Google Drive connector returns.

The Files/Library Drive upload channel hit an explicit temporary upload quota after this block (`Повторите попытку через 2 часа`). Resume with a **single upload stream only** to avoid new duplicate races.

## New Yandex June 30 photos

All source bytes are safe on Drive in independent `ZIP_STORED` packs:
- `/ВСЕ`: 931 JPEG; `6,912,860,320` source bytes; 81/81 packs
- `/ИНДИВИДУАЛЬНЫЕ 1`: 403 JPEG; `2,902,530,815` source bytes; 34/34 packs
- total: 1334 JPEG; `9,815,391,135` source bytes

Final presentation must extract the independent packs back into ordinary JPEG files. Do NOT concatenate photo ZIP packs.

## Finalization policy

1. Video reconstruction = raw byte concatenation in numeric part order, never transcoding/remuxing.
2. Verify every reconstructed MP4 against the exact SHA256 above before deleting parts.
3. Wfolio: restore all 877 JPEGs as ordinary files; keep 56 archive parts until the 877-file result is verified.
4. New-Yandex: restore 931 + 403 = 1334 ordinary JPEGs from independent ZIP packs; keep packs until counts/integrity are verified.
5. Only after final outputs are verified may part folders, ZIP-pack folders, test files and temporary GitHub infrastructure be removed.

## Current infrastructure constraints

- Direct Google Drive connector is currently server-disabled in this session.
- Files/Library Google Drive uploader works, but has a 512 MiB per-file ceiling and may impose temporary upload quota cooldowns.
- Files/Library cannot create or delete Google Drive items in this environment.
- Therefore no verified video transport chunks have been deleted.

## Resume point

- Wfolio ordinary files: resume at archive entry 424 (`5J3B9097.jpg`) and continue through 877 using one upload stream.
- Then restore all 1334 Yandex JPEGs.
- If direct Drive returns, remove documented Wfolio duplicates and use/test a large-file route for the four verified MP4 reconstructions.
