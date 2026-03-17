#!/usr/bin/env python3
"""Golden screenshot regression tool for AutoNavi Maps Flutter.

Compares actual screenshots produced by integration tests against golden
baselines and fails if any image differs by more than the allowed threshold.

Usage:
    python scripts/golden_diff.py <golden_dir> <actual_dir> [--threshold PERCENT]

Examples:
    # CI usage (2 % pixel tolerance):
    python scripts/golden_diff.py \\
        example/integration_test/golden \\
        example/integration_test/screenshots \\
        --threshold 2.0

    # Strict usage for critical screens:
    python scripts/golden_diff.py \\
        example/integration_test/golden \\
        example/integration_test/screenshots \\
        --threshold 0.5

Exit codes:
    0  All screenshots within threshold (or no goldens exist yet).
    1  One or more screenshots exceed the threshold.
    2  Usage error or dependency missing.

Updating goldens:
    After a deliberate visual change is reviewed and approved, copy the new
    screenshots over the goldens:
        cp example/integration_test/screenshots/*.png \\
           example/integration_test/golden/
    Then commit the updated golden files.
"""

import argparse
import math
import os
import sys

try:
    from PIL import Image, ImageChops, ImageFilter
except ImportError:
    print(
        "ERROR: Pillow is required. Install it with:\n"
        "  pip install pillow --break-system-packages",
        file=sys.stderr,
    )
    sys.exit(2)


# ─────────────────────────────────────────────────────────────────────────────
# Core comparison logic
# ─────────────────────────────────────────────────────────────────────────────


def pixel_diff_percent(golden_path: str, actual_path: str) -> float:
    """Return the percentage of pixels that differ between two images.

    Pixels are considered different when any colour channel diverges by more
    than PIXEL_TOLERANCE (out of 255).  This prevents false positives caused
    by sub-pixel anti-aliasing and font-rendering differences between runs.
    """
    PIXEL_TOLERANCE = 10  # channel delta considered noise, not a real change

    golden = Image.open(golden_path).convert("RGB")
    actual = Image.open(actual_path).convert("RGB")

    # If sizes differ, resize actual to match golden before comparing.
    if golden.size != actual.size:
        actual = actual.resize(golden.size, Image.LANCZOS)

    diff = ImageChops.difference(golden, actual)
    pixels = list(diff.getdata())
    total = len(pixels)

    changed = sum(
        1 for p in pixels if any(channel > PIXEL_TOLERANCE for channel in p)
    )

    return changed / total * 100.0


def _write_diff_image(golden_path: str, actual_path: str, diff_path: str) -> None:
    """Write an amplified diff image for human inspection."""
    try:
        from PIL import ImageEnhance

        golden = Image.open(golden_path).convert("RGB")
        actual = Image.open(actual_path).convert("RGB")
        if golden.size != actual.size:
            actual = actual.resize(golden.size, Image.LANCZOS)

        diff = ImageChops.difference(golden, actual)
        # Amplify so small differences are visible.
        amplified = ImageEnhance.Brightness(diff).enhance(10)
        amplified.save(diff_path)
    except Exception as exc:
        print(f"  ⚠  Could not write diff image: {exc}")


# ─────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare integration-test screenshots against golden baselines.",
    )
    parser.add_argument("golden_dir", help="Directory containing golden PNG files.")
    parser.add_argument("actual_dir", help="Directory containing actual PNG files.")
    parser.add_argument(
        "--threshold",
        type=float,
        default=2.0,
        metavar="PERCENT",
        help="Maximum allowed pixel difference in percent (default: 2.0).",
    )
    parser.add_argument(
        "--diff-dir",
        default=None,
        metavar="DIR",
        help="Optional directory to write amplified diff images for failed cases.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    golden_dir = args.golden_dir
    actual_dir = args.actual_dir
    threshold = args.threshold
    diff_dir = args.diff_dir

    if not os.path.isdir(golden_dir):
        print(
            f"ℹ️  Golden directory '{golden_dir}' does not exist yet.\n"
            "   Run the integration tests once and copy screenshots/ → golden/\n"
            "   to establish the baseline.",
        )
        return 0  # Not a failure — first-run setup.

    if not os.path.isdir(actual_dir):
        print(
            f"ERROR: Actual screenshots directory '{actual_dir}' not found.\n"
            "       Run the integration tests first.",
            file=sys.stderr,
        )
        return 1

    golden_files = sorted(
        f for f in os.listdir(golden_dir) if f.lower().endswith(".png")
    )

    if not golden_files:
        print(
            f"ℹ️  No golden PNG files found in '{golden_dir}'.\n"
            "   Copy screenshots/ → golden/ to establish baselines."
        )
        return 0

    if diff_dir:
        os.makedirs(diff_dir, exist_ok=True)

    failures: list[str] = []
    passed: list[str] = []
    missing: list[str] = []

    for golden_filename in golden_files:
        golden_path = os.path.join(golden_dir, golden_filename)
        actual_path = os.path.join(actual_dir, golden_filename)

        if not os.path.exists(actual_path):
            missing.append(golden_filename)
            print(f"❌ MISSING  {golden_filename}  (no actual screenshot found)")
            continue

        pct = pixel_diff_percent(golden_path, actual_path)

        if pct > threshold:
            failures.append(golden_filename)
            print(
                f"❌ FAIL     {golden_filename}  "
                f"{pct:.2f}% pixels changed (threshold {threshold:.1f}%)"
            )
            if diff_dir:
                diff_path = os.path.join(diff_dir, f"diff_{golden_filename}")
                _write_diff_image(golden_path, actual_path, diff_path)
                print(f"           diff image → {diff_path}")
        else:
            passed.append(golden_filename)
            print(
                f"✅ PASS     {golden_filename}  "
                f"{pct:.2f}% changed (threshold {threshold:.1f}%)"
            )

    # ── Summary ──────────────────────────────────────────────────────────────
    total = len(golden_files)
    n_passed = len(passed)
    n_failed = len(failures)
    n_missing = len(missing)

    print()
    print(
        f"Results: {n_passed}/{total} passed, "
        f"{n_failed} failed, {n_missing} missing"
    )

    if failures or missing:
        print()
        if failures:
            print("Failed screenshots (exceeded pixel threshold):")
            for f in failures:
                print(f"  - {f}")
        if missing:
            print("Missing screenshots (not produced by this test run):")
            for f in missing:
                print(f"  - {f}")
        return 1

    print("All golden comparisons passed ✓")
    return 0


if __name__ == "__main__":
    sys.exit(main())
