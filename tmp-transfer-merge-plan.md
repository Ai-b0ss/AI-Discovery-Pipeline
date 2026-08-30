# TEMP transfer merge / restore plan

This file is a safety checkpoint for the Yandex/Wfolio -> Google Drive transfer. Do not delete the split-part folders until the reconstructed originals are byte-verified.

## Rule

Everything that was split only because of transfer limits must be reconstructed to its original form. `.partNNN` and temporary ZIP-pack folders are transport format, not final user-facing format.

## School videos — byte concatenation

Destination root: `/Google Drive/школа 1259`

1. `/Выпускной готовое/выпускной клип.mp4 — части`
   - parts: `выпускной клип.mp4.part001` ... `.part013`
   - expected output: `/Выпускной готовое/выпускной клип.mp4`
   - expected size: `1,241,060,815` bytes
   - source SHA-256: `0fcadc1b53c6f90c16fe7125a07014a9e15fad0281d8c63f4b7f218c255f39cd`

2. `/Выпускной готовое/выпускной.mp4 — части`
   - parts: `выпускной.mp4.part001` ... `.part113`
   - expected output: `/Выпускной готовое/выпускной.mp4`
   - expected size: `11,294,518,113` bytes
   - source SHA-256: `628bdd80894cd8296838d2011d0ed0f2ab4a3912629fec35eabe9bcabaf40ed9`
   - parts 001-112 are 100,000,000 bytes; part113 is 94,518,113 bytes

3. `/Последний звонок готовое/Последний звонок клип.mp4 — части`
   - parts: `Последний звонок клип.mp4.part001` ... `.part016`
   - expected output: `/Последний звонок готовое/Последний звонок клип.mp4`
   - expected size: `1,528,082,371` bytes
   - source SHA-256: `5594451b481999b9ff8e2e656a937d48a603ae1d65148acd2f2fb30ab7ac27cd`

4. `/Последний звонок готовое/Последний звонок.mp4 — части`
   - parts: `Последний звонок.mp4.part001` ... `.part051`
   - expected output: `/Последний звонок готовое/Последний звонок.mp4`
   - expected size: `5,053,962,886` bytes
   - source SHA-256: `12c31327edf92c6d0489b97738807d73fc696c7ad558edc1dedf624841f82856`

All four SHA-256 values above were independently re-read from the public Yandex source on 2026-08-30. Concatenation must be raw byte concatenation in numeric order. Do not unzip/decode/re-encode the MP4 parts.

## Wfolio archive — byte concatenation

Drive location: `/Google Drive/30 июня 2026/Wfolio — СОХО 30.06.2026 (терраса)/СОХО 30.06.2026 (терраса).zip — части`

- parts: `СОХО 30.06.2026 (терраса).zip.part001` ... `.part056`
- expected reconstructed output: `/Google Drive/30 июня 2026/Wfolio — СОХО 30.06.2026 (терраса)/СОХО 30.06.2026 (терраса).zip`
- expected size: `5,584,535,044` bytes
- parts 001-055 are 100,000,000 bytes; part056 is 84,535,044 bytes

After reconstruction, verify ZIP integrity before removing transport parts. The old public archive URL later returned 404, so byte-size + ZIP CRC is the current minimum verification gate unless a fresh archive URL is recovered.

## Yandex June-30 photos — extract packs, DO NOT concatenate ZIPs

Source contained 1,334 independent JPEG files; the ZIPs were only transport packs. Final state should be normal photo files/folders, not one concatenated archive.

- `/Google Drive/30 июня 2026/Яндекс Диск — фото/ВСЕ — ZIP-пакеты`: 81 packs, source `/ВСЕ`, 931 photos, 6,912,860,320 raw bytes.
- `/Google Drive/30 июня 2026/Яндекс Диск — фото/ИНДИВИДУАЛЬНЫЕ 1 — ZIP-пакеты`: 34 packs, source `/ИНДИВИДУАЛЬНЫЕ 1`, 403 photos, 2,902,530,815 raw bytes.

Restore by extracting every ZIP pack into corresponding final folders while preserving archive member paths. Reject path traversal and conflicting duplicate filenames. Total expected: 1,334 JPEGs, 9,815,391,135 source bytes.

## Verified Drive transport inventory (2026-08-30)

- `выпускной клип.mp4`: 13/13 parts present; final part `41,060,815` bytes.
- `Последний звонок клип.mp4`: 16/16 parts present; final part `28,082,371` bytes.
- `Последний звонок.mp4`: 51/51 parts present; final part `53,962,886` bytes.
- Wfolio ZIP: 56/56 parts present; final part `84,535,044` bytes.
- Yandex `/ВСЕ`: packs 001-081 present; pack081 `25,957,715` bytes.
- Yandex `/ИНДИВИДУАЛЬНЫЕ 1`: packs 001-034 present; pack034 `33,308,764` bytes.
- `выпускной.mp4`: Drive currently confirmed contiguous through part100. Fresh parts 101-113 are retained in GitHub Actions for 7 days; part113 is `94,518,113` bytes. Do not mark 101-113 as Drive-resident until a Drive listing proves it.

## Cleanup gate

Delete transport part/pack folders only after all of the following are true:

1. reconstructed output exists in the parent folder;
2. exact byte size matches the expected size/count above;
3. MP4/ZIP is readable; Wfolio ZIP passes integrity check;
4. every Yandex MP4 reconstructed SHA-256 matches the source SHA-256 above;
5. photo extraction yields exactly 931 + 403 = 1,334 source files without conflicts.

Temporary GitHub workflows/branch and Drive test files are cleanup-only and must remain until this gate is complete.
