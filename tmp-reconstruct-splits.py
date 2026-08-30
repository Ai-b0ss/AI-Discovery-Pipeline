#!/usr/bin/env python3
"""Reconstruct transport-split files and unpack transport photo ZIPs.

Safe properties:
- raw byte concatenation only for .partNNN files;
- exact part count and expected size checks;
- optional SHA-256 verification;
- ZIP integrity test for reconstructed Wfolio archive;
- safe ZIP extraction with traversal/conflicting-duplicate rejection.

Run this only against a filesystem where the Google Drive tree is mounted/synced locally.
Do not delete source part folders until every verification passes.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import sys
import zipfile
from pathlib import Path


def sha256_file(path: Path, block: int = 8 * 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            b = f.read(block)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def concat_parts(
    part_dir: Path,
    prefix: str,
    count: int,
    output: Path,
    expected_size: int,
    expected_sha256: str | None = None,
    test_zip: bool = False,
) -> None:
    parts = [part_dir / f"{prefix}.part{i:03d}" for i in range(1, count + 1)]
    missing = [str(p) for p in parts if not p.is_file()]
    if missing:
        raise RuntimeError(f"missing {len(missing)} parts, first={missing[:5]}")

    total = sum(p.stat().st_size for p in parts)
    if total != expected_size:
        raise RuntimeError(f"part-size sum mismatch: expected={expected_size} actual={total}")

    output.parent.mkdir(parents=True, exist_ok=True)
    temp = output.with_name(output.name + ".reconstructing")
    if temp.exists():
        temp.unlink()

    h = hashlib.sha256()
    written = 0
    with temp.open("wb") as dst:
        for idx, part in enumerate(parts, 1):
            with part.open("rb") as src:
                while True:
                    b = src.read(8 * 1024 * 1024)
                    if not b:
                        break
                    dst.write(b)
                    h.update(b)
                    written += len(b)
            print(f"[{idx:03d}/{count:03d}] {part.name} -> {written:,} bytes", flush=True)
        dst.flush()
        os.fsync(dst.fileno())

    if written != expected_size or temp.stat().st_size != expected_size:
        raise RuntimeError(f"output-size mismatch expected={expected_size} written={written} stat={temp.stat().st_size}")

    digest = h.hexdigest()
    if expected_sha256 and digest.lower() != expected_sha256.lower():
        raise RuntimeError(f"SHA-256 mismatch expected={expected_sha256} actual={digest}")

    if test_zip:
        with zipfile.ZipFile(temp, "r") as zf:
            bad = zf.testzip()
            if bad is not None:
                raise RuntimeError(f"ZIP CRC failure in member: {bad}")

    os.replace(temp, output)
    print(f"OK {output} bytes={written} sha256={digest}")


def _safe_member_path(root: Path, member: str) -> Path:
    # ZIP member names are POSIX-like; reject absolute / parent traversal.
    candidate = (root / member).resolve()
    root_resolved = root.resolve()
    try:
        candidate.relative_to(root_resolved)
    except ValueError:
        raise RuntimeError(f"unsafe archive path: {member!r}")
    return candidate


def extract_packs(pack_dir: Path, pattern: str, output_dir: Path, expected_files: int) -> None:
    packs = sorted(pack_dir.glob(pattern))
    if not packs:
        raise RuntimeError(f"no packs matched {pack_dir / pattern}")
    output_dir.mkdir(parents=True, exist_ok=True)

    seen: dict[str, tuple[int, int]] = {}
    extracted = 0
    for pidx, pack in enumerate(packs, 1):
        with zipfile.ZipFile(pack, "r") as zf:
            bad = zf.testzip()
            if bad is not None:
                raise RuntimeError(f"ZIP CRC failure: pack={pack.name} member={bad}")
            for info in zf.infolist():
                if info.is_dir():
                    continue
                dest = _safe_member_path(output_dir, info.filename)
                key = str(dest.relative_to(output_dir.resolve()))
                fingerprint = (info.file_size, info.CRC)
                if key in seen and seen[key] != fingerprint:
                    raise RuntimeError(f"conflicting duplicate archive member: {key}")
                if key in seen:
                    continue
                seen[key] = fingerprint
                dest.parent.mkdir(parents=True, exist_ok=True)
                with zf.open(info, "r") as src, dest.open("wb") as dst:
                    shutil.copyfileobj(src, dst, 8 * 1024 * 1024)
                if dest.stat().st_size != info.file_size:
                    raise RuntimeError(f"extracted-size mismatch: {key}")
                extracted += 1
        print(f"[{pidx:03d}/{len(packs):03d}] extracted {pack.name}; files={extracted}", flush=True)

    if extracted != expected_files:
        raise RuntimeError(f"file-count mismatch expected={expected_files} actual={extracted}")
    print(f"OK extracted {extracted} files into {output_dir}")


def school(root: Path) -> None:
    grad = root / "Выпускной готовое"
    bell = root / "Последний звонок готовое"
    concat_parts(
        grad / "выпускной клип.mp4 — части", "выпускной клип.mp4", 13,
        grad / "выпускной клип.mp4", 1_241_060_815,
        "0fcadc1b53c6f90c16fe7125a07014a9e15fad0281d8c63f4b7f218c255f39cd",
    )
    concat_parts(
        grad / "выпускной.mp4 — части", "выпускной.mp4", 113,
        grad / "выпускной.mp4", 11_294_518_113,
    )
    concat_parts(
        bell / "Последний звонок клип.mp4 — части", "Последний звонок клип.mp4", 16,
        bell / "Последний звонок клип.mp4", 1_528_082_371,
    )
    concat_parts(
        bell / "Последний звонок.mp4 — части", "Последний звонок.mp4", 51,
        bell / "Последний звонок.mp4", 5_053_962_886,
    )


def wfolio(root: Path) -> None:
    base = root / "Wfolio — СОХО 30.06.2026 (терраса)"
    concat_parts(
        base / "СОХО 30.06.2026 (терраса).zip — части",
        "СОХО 30.06.2026 (терраса).zip", 56,
        base / "СОХО 30.06.2026 (терраса).zip", 5_584_535_044,
        test_zip=True,
    )


def photos(root: Path) -> None:
    base = root / "Яндекс Диск — фото"
    extract_packs(base / "ВСЕ — ZIP-пакеты", "*.zip", base / "ВСЕ", 931)
    extract_packs(base / "ИНДИВИДУАЛЬНЫЕ 1 — ZIP-пакеты", "*.zip", base / "ИНДИВИДУАЛЬНЫЕ 1", 403)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["school", "wfolio", "photos", "all"])
    ap.add_argument("--school-root", type=Path, help="mounted path to Google Drive/школа 1259")
    ap.add_argument("--june30-root", type=Path, help="mounted path to Google Drive/30 июня 2026")
    args = ap.parse_args()

    if args.mode in {"school", "all"}:
        if not args.school_root:
            ap.error("--school-root is required for school/all")
        school(args.school_root)
    if args.mode in {"wfolio", "photos", "all"}:
        if not args.june30_root:
            ap.error("--june30-root is required for wfolio/photos/all")
        if args.mode in {"wfolio", "all"}:
            wfolio(args.june30_root)
        if args.mode in {"photos", "all"}:
            photos(args.june30_root)


if __name__ == "__main__":
    main()
