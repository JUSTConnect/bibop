#!/usr/bin/env python3
from __future__ import annotations

import base64
import hashlib
import subprocess
import tarfile
from pathlib import Path

LEGACY_REF = "refs/remotes/origin/issue1162-legacy"
LEGACY_BRANCH = "codex/bip-architecture-coordinators-02f7-final-cleanup"
CHUNK_DIR = Path("/tmp/issue-1162-chunks")
EXTRACT_DIR = Path("/tmp/issue-1162-extracted")
SOURCE_B64 = Path("/tmp/issue-1162-source.b64")
SOURCE_ARCHIVE = Path("/tmp/issue-1162-source.tar.gz")

EXPECTED_CHUNKS = {
    "part00.b64": "7f27f0c142b9cb1eb39a28e06449378bdaf99b8d519355b2df5108d4064c912e",
    "part01.b64": "0979aa805d9a025a58efb77761169a94a88f4e1506c20a019491e7e3390d447e",
    "fix02-00.b64": "ce23e5a9e8574a5e5d0417ee9b47c4fadc8ff206484e0035c9ca2b868a62c0ea",
    "fix02-01.b64": "529aa39b16fad99ab2cc1e95b41263869b4bbc420790abec791e57bf599cef6e",
    "fix02-02.b64": "bc081582c04b53ec9ce4e50f4ea17f78f2c26096dca5ee13c6c88e1ffb18d9f9",
    "fix02-03.b64": "1a4baa6335c0498915384a415051fbdf1b0d08a5d8357af07d071cb47286d55c",
    "fix03-01.b64": "00a39a1a8599b953134e7df7a839181a2494cf15d9911b728805481471eda994",
    "fix03-02.b64": "7a6af70dd84a486a6c5ca47d5995fdcb3aef8b62194bac5326572914382dbba8",
}

ORDER = [
    "part00.b64",
    "part01.b64",
    "fix02-00.b64",
    "fix02-01.b64",
    "fix02-02.b64",
    "fix02-03.b64",
    "fix03-00.corrected.b64",
    "fix03-01.b64",
    "fix03-02.b64",
]


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_show(path: str) -> bytes:
    result = subprocess.run(
        ["git", "show", f"{LEGACY_REF}:.github/issue-1162-transport/{path}"],
        check=True,
        stdout=subprocess.PIPE,
    )
    return result.stdout


def main() -> None:
    subprocess.run(
        [
            "git",
            "fetch",
            "origin",
            f"{LEGACY_BRANCH}:{LEGACY_REF}",
        ],
        check=True,
    )
    CHUNK_DIR.mkdir(parents=True, exist_ok=True)

    for name, expected in EXPECTED_CHUNKS.items():
        data = git_show(name)
        actual = sha256_bytes(data)
        if actual != expected:
            raise SystemExit(f"checksum mismatch for {name}: {actual}")
        (CHUNK_DIR / name).write_bytes(data)

    damaged = git_show("fix03-00.b64").decode("ascii")
    if len(damaged) != 4999:
        raise SystemExit(f"unexpected fix03-00 length: {len(damaged)}")
    target = "e10f6b3afce161f5830572f585a00a4f8c3dc12ebaeac933233bd270eda2cb40"
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    corrected: str | None = None
    for index in range(len(damaged) + 1):
        for char in alphabet:
            candidate = damaged[:index] + char + damaged[index:]
            if sha256_bytes(candidate.encode("ascii")) == target:
                corrected = candidate
                print(f"repaired fix03-00 at index {index} with {char!r}")
                break
        if corrected is not None:
            break
    if corrected is None:
        raise SystemExit("unable to repair fix03-00")
    (CHUNK_DIR / "fix03-00.corrected.b64").write_text(corrected, encoding="ascii")

    combined = b"".join((CHUNK_DIR / name).read_bytes() for name in ORDER)
    if len(combined) != 74280:
        raise SystemExit(f"unexpected combined base64 length: {len(combined)}")
    expected_b64 = "a87e0f0470c6385ee38cc178f9ff8c59b63b4fed8fd2637ff780e9b105e28111"
    if sha256_bytes(combined) != expected_b64:
        raise SystemExit("combined base64 checksum mismatch")
    SOURCE_B64.write_bytes(combined)

    archive = base64.b64decode(combined, validate=True)
    expected_archive = "a28927aaa543b63049506591757e9b5b4c507f2471d869524fd51ccbe7f7a13e"
    if sha256_bytes(archive) != expected_archive:
        raise SystemExit("source archive checksum mismatch")
    SOURCE_ARCHIVE.write_bytes(archive)

    if EXTRACT_DIR.exists():
        subprocess.run(["rm", "-rf", str(EXTRACT_DIR)], check=True)
    EXTRACT_DIR.mkdir(parents=True)
    with tarfile.open(SOURCE_ARCHIVE, "r:gz") as handle:
        handle.extractall(EXTRACT_DIR, filter="data")
    print(f"extracted verified source archive to {EXTRACT_DIR}")


if __name__ == "__main__":
    main()
