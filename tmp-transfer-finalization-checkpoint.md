# Transfer finalization checkpoint — 2026-08-30

Temporary operational checkpoint. Transport chunks are NOT final deliverables. Do not delete any sole safe transport copy until reconstructed output is independently verified.

## School / old Yandex share

All four MP4 sources are fully represented on Google Drive as exact byte-range parts:

- `выпускной клип.mp4`: 13 parts; `1,241,060,815` bytes; SHA256 `0fcadc1b53c6f90c16fe7125a07014a9e15fad0281d8c63f4b7f218c255f39cd`.
- `Последний звонок клип.mp4`: 16 parts; `1,528,082,371` bytes; SHA256 `5594451b481999b9ff8e2e656a937d48a603ae1d65148acd2f2fb30ab7ac27cd`.
- `Последний звонок.mp4`: 51 parts; `5,053,962,886` bytes; SHA256 `12c31327edf92c6d0489b97738807d73fc696c7ad558edc1dedf624841f82856`.
- `выпускной.mp4`: 113 parts; `11,294,518,113` bytes; SHA256 `628bdd80894cd8296838d2011d0ed0f2ab4a3912629fec35eabe9bcabaf40ed9`.

Old-Yandex total: `19,117,624,185` bytes. `выпускной.mp4` was audited as parts `001..113`; parts 001..112 are 100,000,000 bytes and part113 is 94,518,113 bytes.

All four original MP4s also have independently downloaded whole-source GitHub Actions raw artifacts retained for 7 days:
- graduation clip artifact `9731156804`, digest equals source SHA.
- last-bell clip artifact `9731167379`, digest equals source SHA.
- last-bell full artifact `9731170999`, digest equals source SHA.
- graduation full artifact `9731207395`, digest equals source SHA.

Current connector/file gateways reject single transfers above 512 MiB, so verified Drive video part sets MUST remain until a true large-file upload route exists.

## Wfolio SOHO 30.06.2026

Original archive size: `5,584,535,044` bytes. Source content: **877 JPEGs**, JPEG byte total `5,584,348,256`. 56/56 transport archive parts are present on Drive; reconstructed archive previously passed `ZipFile.testzip()`.

Ordinary-JPEG restoration on Drive is confirmed through source entry **423** (`5J3B9094.jpg`). A Drive listing shows 454 JPEG records representing those 423 unique names, i.e. 31 excess duplicates from an earlier parallel-upload race. Duplicate cleanup IDs are documented separately; Files/Library cannot delete Google Drive items, so cleanup waits for direct Drive connector recovery.

### Ready remainder 424..877

Fresh GitHub Actions run `33309118687` rebuilt the complete remaining source range **424..877** directly from the Wfolio original archive and completed successfully.

It produced 9 independent ZIP_STORED restore packs, all retained to 2026-09-06:
- pack001 artifact `9731470532`: indices 424-478, 55 files, raw 345,719,686 bytes, ZIP 345,731,148, digest `99c7069e6f9cedf055527307e0adbb891d99cfb3bcfe963de4f20fb3ad53b628`.
- pack002 artifact `9731471209`: 479-531, 53 files, raw 346,793,143, ZIP 346,804,189, digest `5c826e11c69d794eae03b312d7a15f3b3f0b848b0c8536ad67ccb760fcdc8326`.
- pack003 artifact `9731471936`: 532-577, 46 files, raw 340,780,757, ZIP 340,790,347, digest `85c71e5bf1ef9f364c02a978ed3ae5fc0ebc7e0538f5cd65f2ca9a755f699767`.
- pack004 artifact `9731472689`: 578-624, 47 files, raw 349,375,530, ZIP 349,385,328, digest `afc361fbd997b43e009d93e015ac0bffed6abbf21ec47911f0cef368741c33f6`.
- pack005 artifact `9731473410`: 625-678, 54 files, raw 349,365,109, ZIP 349,376,363, digest `68d62c1e0eed59b53881671d3e1c41b2db93410c50531274bbec7be482030be9`.
- pack006 artifact `9731474115`: 679-732, 54 files, raw 347,024,988, ZIP 347,036,242, digest `abac8975b66fd08b4e134d4de1314f955b902b6877eebe18db77bfe444b7338f`.
- pack007 artifact `9731474762`: 733-788, 56 files, raw 347,291,616, ZIP 347,303,286, digest `dca08f5f79c60d67d21379099180dcbd61ab1d3b28abc0363cde0a0b70914fff`.
- pack008 artifact `9731475427`: 789-851, 63 files, raw 346,917,686, ZIP 346,930,812, digest `c4a7d190250bcf2dafc5bb0d9107c827ed3ae1c94fa427b4eee7601d0dbbcd59`.
- pack009 artifact `9731475935`: 852-877, 26 files, raw 171,131,647, ZIP 171,137,077, digest `f4a375bceec5dbb83fdc35a035e9f2c447cdcecd51f6c8597cf4233fda162f12`.
- manifest artifact `9731476183`.

All 9 packs were downloaded into the current container, independently SHA256-checked against the artifact digests, passed `ZipFile.testzip()`, and every member's size/CRC matched the pack manifest. They were then extracted to `/mnt/data/wfolio_ready_424_877`; all **454 JPEGs** were independently verified against their per-file SHA256 in the canonical Wfolio manifest. Local pack ZIP duplicates were deleted after verification; the GitHub artifacts remain as safety copies.

Drive Files/Library upload throttle is currently in its final cooldown (latest response: retry in 3 minutes). Resume with a single upload stream at source entry **424 (`5J3B9097.jpg`)**, then continue through 877. Do not run multiple upload streams concurrently.

## New Yandex June 30 photos

All source bytes are safe on Drive in independent `ZIP_STORED` packs:
- `/ВСЕ`: 931 JPEG; `6,912,860,320` source bytes; 81/81 packs.
- `/ИНДИВИДУАЛЬНЫЕ 1`: 403 JPEG; `2,902,530,815` source bytes; 34/34 packs.
- total: 1334 JPEG; `9,815,391,135` source bytes.

Preparation for final extraction has begun: Drive packs `/ВСЕ` 001..005 were materialized locally and all five passed `ZipFile.testzip()`; together they contain 57 original JPEGs. Final destination subfolders `ВСЕ` and `ИНДИВИДУАЛЬНЫЕ 1` cannot currently be created through Files/Library because Google Drive folder creation is unsupported there; creation waits for direct Drive connector recovery or another valid folder-creation route.

## Finalization policy

1. Video reconstruction = raw byte concatenation in numeric part order, never transcoding/remuxing.
2. Verify every reconstructed MP4 against the exact SHA256 above before deleting parts.
3. Wfolio: restore all 877 JPEGs as ordinary files; keep 56 archive parts until the 877-file result is verified.
4. New-Yandex: restore 931 + 403 = 1334 ordinary JPEGs from independent ZIP packs; keep packs until counts/integrity are verified.
5. Only after final outputs are verified may part folders, ZIP-pack folders, test files and temporary GitHub infrastructure be removed.

## Current infrastructure constraints

- Direct Google Drive connector is server-disabled when actually invoked, despite its tools appearing in discovery.
- Files/Library Google Drive uploader can create ordinary files but has a 512 MiB per-file ceiling and temporary upload throttling.
- Files/Library cannot create/delete Google Drive folders/items in this environment.
- GitHub Actions can hold exact whole MP4s, but connector download also rejects artifacts above 512 MiB.

## Resume point

1. Wfolio: after cooldown, upload prepared verified files 424..877 from `/mnt/data/wfolio_ready_424_877` with **one stream only**, then verify 877 unique source names against canonical manifest.
2. New-Yandex: create final `ВСЕ` and `ИНДИВИДУАЛЬНЫЕ 1` folders when a capable Drive route is available, then extract/restore all 1334 JPEGs.
3. Keep searching for a true >512 MiB Drive upload route for four verified whole MP4 files; never delete the complete Drive part sets prematurely.
