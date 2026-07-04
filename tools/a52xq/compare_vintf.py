#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

HEADER = re.compile(r"^######## (.+) ########$", re.MULTILINE)


def split_report(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    matches = list(HEADER.finditer(text))
    result: dict[str, str] = {}

    for index, match in enumerate(matches):
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        result[match.group(1)] = text[start:end].strip()

    return result


def parse_xml(text: str, label: str) -> ET.Element | None:
    try:
        return ET.fromstring(text)
    except ET.ParseError as exc:
        print(f"Warning: could not parse {label}: {exc}", file=sys.stderr)
        return None


def hal_names(root: ET.Element, required_only: bool = False) -> set[str]:
    names: set[str] = set()

    for hal in root.findall("hal"):
        if required_only and hal.attrib.get("optional", "false").lower() == "true":
            continue

        name = hal.findtext("name")
        if name:
            names.add(name.strip())

    return names


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("donor_root", type=Path)
    parser.add_argument("--baseline-report", type=Path, required=True)
    parser.add_argument("--fcm-level", type=int, default=5)
    parser.add_argument("--output", type=Path, default=Path("vintf_comparison.json"))
    args = parser.parse_args()

    sections = split_report(args.baseline_report)
    provided: set[str] = set()

    for name, content in sections.items():
        if name.startswith("/vendor/etc/vintf/manifest") or name.startswith(
            "/odm/etc/vintf/manifest"
        ):
            root = parse_xml(content, name)
            if root is not None and root.tag == "manifest":
                provided |= hal_names(root)

    candidates = [
        args.donor_root
        / "system"
        / "etc"
        / "vintf"
        / f"compatibility_matrix.{args.fcm_level}.xml",
        args.donor_root
        / "etc"
        / "vintf"
        / f"compatibility_matrix.{args.fcm_level}.xml",
    ]
    matrix_path = next((path for path in candidates if path.is_file()), None)

    if matrix_path is None:
        raise FileNotFoundError(
            f"compatibility_matrix.{args.fcm_level}.xml was not found"
        )

    required = hal_names(ET.parse(matrix_path).getroot(), required_only=True)
    missing = required - provided

    output = {
        "fcm_level": args.fcm_level,
        "donor_matrix": str(matrix_path),
        "provided_device_hal_names": sorted(provided),
        "required_framework_hal_names": sorted(required),
        "missing_required_hal_names": sorted(missing),
        "note": (
            "This is a first-pass HAL-name comparison. Versions, instances, "
            "kernel requirements and SELinux still need separate review."
        ),
    }
    args.output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")

    print(f"Provided HAL names: {len(provided)}")
    print(f"Required HAL names: {len(required)}")
    print(f"Missing required names: {len(missing)}")

    for name in sorted(missing):
        print(f"MISSING: {name}")

    print(f"Output: {args.output}")
    return 3 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
