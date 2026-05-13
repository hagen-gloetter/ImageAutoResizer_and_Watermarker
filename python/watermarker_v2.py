"""watermarker_v2.py — Cross-platform image watermarking and resizing tool.

Replicates the functionality of imageAutoResizer_and_Watermarker.sh
using pure Python/Pillow. Produces identical output on macOS, Windows
and Ubuntu.

Usage:
    python watermarker_v2.py <source-folder> [options]

Example:
    python watermarker_v2.py ./my-photos/
    python watermarker_v2.py ./my-photos/ --logo ./logos/custom.png
    python watermarker_v2.py ./my-photos/ --title-font "Georgia" --title-size 60

Dependencies:
    Pillow>=10.0, pillow-heif>=0.10.0 (optional, for HEIC support)

Exit codes:
    0 — Success
    1 — Error (missing folder, missing logo, invalid arguments)
"""

from __future__ import annotations

import argparse
import platform
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path
from typing import Final

from PIL import Image, ImageDraw, ImageFont

# ---------------------------------------------------------------------------
# Optional HEIC support
# ---------------------------------------------------------------------------
_HEIF_AVAILABLE: bool = False
try:
    from pillow_heif import register_heif_opener

    register_heif_opener()
    _HEIF_AVAILABLE = True
except ImportError:
    pass

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SUPPORTED_EXTENSIONS: Final[frozenset[str]] = frozenset(
    {".jpg", ".jpeg", ".png", ".heic", ".heif", ".tiff", ".tif", ".raw", ".rw2"}
)

RESOLUTIONS: Final[dict[str, int]] = {
    "6k": 6000,
    "4k": 4000,
    "2k": 1680,
}

JPEG_QUALITY_DEFAULT: Final[int] = 85
BASE_WIDTH: Final[int] = 6000
OFFSET_Y: Final[int] = 100  # fixed vertical margin matching shell script

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Config:
    """Immutable runtime configuration."""

    source_folder: Path
    logo_path: Path
    logo_position: str  # SW, SE, NW, NE
    title_font_path: Path
    title_size: int
    body_font_path: Path
    body_size: int
    text_color: str
    jpeg_quality: int
    skip_existing: bool
    workers: int


# ---------------------------------------------------------------------------
# Font resolution
# ---------------------------------------------------------------------------

# Well-known font filenames per logical name (case-insensitive lookup).
_FONT_FILENAMES: dict[str, list[str]] = {
    "times new roman": [
        "Times New Roman.ttf",
        "TimesNewRoman.ttf",
        "times_new_roman.ttf",
        "times.ttf",
        "Times.ttf",
    ],
    "arial": [
        "Arial.ttf",
        "arial.ttf",
    ],
    "georgia": ["Georgia.ttf", "georgia.ttf"],
    "helvetica": ["Helvetica.ttf", "helvetica.ttf"],
    "courier new": ["Courier New.ttf", "cour.ttf"],
}

def _system_font_dirs() -> list[Path]:
    """Return platform-specific system font directories."""
    system = platform.system()
    if system == "Darwin":
        return [
            Path("/System/Library/Fonts/Supplemental"),
            Path("/System/Library/Fonts"),
            Path("/Library/Fonts"),
            Path.home() / "Library" / "Fonts",
        ]
    if system == "Linux":
        return [
            Path("/usr/share/fonts/truetype/msttcorefonts"),
            Path("/usr/share/fonts/truetype"),
            Path("/usr/share/fonts"),
            Path("/usr/local/share/fonts"),
            Path.home() / ".local" / "share" / "fonts",
        ]
    if system == "Windows":
        windir = Path("C:/Windows/Fonts")
        return [windir]
    return []


def resolve_font(name_or_path: str, script_dir: Path) -> Path:
    """Resolve a font name or path to an actual .ttf file.

    Search order:
      1. If *name_or_path* is a file path that exists, return it directly.
      2. Look in ``<script_dir>/fonts/`` (bundled fonts).
      3. Look in system font directories.
      4. Return *name_or_path* as-is and let Pillow try (may fall back to default).
    """
    # 1) Direct path?
    direct = Path(name_or_path)
    if direct.is_file():
        return direct

    # Normalise logical name for lookup
    key = name_or_path.strip().lower()
    candidates = _FONT_FILENAMES.get(key, [name_or_path + ".ttf"])

    # 2) Bundled fonts/ folder
    fonts_dir = script_dir / "fonts"
    if fonts_dir.is_dir():
        for fname in candidates:
            p = fonts_dir / fname
            if p.is_file():
                return p
        # case-insensitive scan
        existing = {f.name.lower(): f for f in fonts_dir.iterdir() if f.is_file()}
        for fname in candidates:
            match = existing.get(fname.lower())
            if match is not None:
                return match

    # 3) System directories
    for sys_dir in _system_font_dirs():
        if not sys_dir.is_dir():
            continue
        for fname in candidates:
            p = sys_dir / fname
            if p.is_file():
                return p
        # Try recursive search for deeply nested font dirs (Linux)
        for fname in candidates:
            hits = list(sys_dir.rglob(fname))
            if hits:
                return hits[0]

    # 4) Fallback — return the raw string, Pillow may still resolve it
    print(f"Warning: Font '{name_or_path}' nicht gefunden — Pillow-Default wird verwendet.", file=sys.stderr)
    return Path(name_or_path)


def _load_font(font_path: Path, size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """Load a TrueType font, falling back to Pillow default."""
    try:
        return ImageFont.truetype(str(font_path), size)
    except OSError:
        try:
            # Try as font name (Pillow may find it via OS font config)
            return ImageFont.truetype(font_path.name, size)
        except OSError:
            print(f"Warning: Font '{font_path}' konnte nicht geladen werden — nutze Default-Font.", file=sys.stderr)
            return ImageFont.load_default()


# ---------------------------------------------------------------------------
# Image processing helpers
# ---------------------------------------------------------------------------


def resize_to_width(img: Image.Image, target_width: int) -> Image.Image:
    """Resize *img* to *target_width* maintaining aspect ratio (Lanczos)."""
    if img.width == target_width:
        return img.copy()
    ratio = target_width / img.width
    target_height = round(img.height * ratio)
    return img.resize((target_width, target_height), Image.LANCZOS)


def apply_text_overlay(img: Image.Image, text_path: Path, config: Config) -> Image.Image:
    """Render text from *text_path* onto *img* (NorthWest gravity).

    Line 1  → headline (title font/size)
    Lines 2+ → body   (body font/size)

    Margins match the shell script:
      X-offset = width / 50  (120 px at 6000 px)
      Y-offset = 100 px (fixed)
    """
    if not text_path.is_file():
        print(f"  TEXTFILE NOT found: >{text_path.name}<")
        return img

    text = text_path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines:
        return img

    print(f"  TEXTFILE found: >{text_path.name}<")

    title_font = _load_font(config.title_font_path, config.title_size)
    body_font = _load_font(config.body_font_path, config.body_size)

    draw = ImageDraw.Draw(img)
    offset_x = img.width // 50
    offset_y = OFFSET_Y

    # Headline (line 1)
    headline = lines[0]
    draw.text((offset_x, offset_y), headline, font=title_font, fill=config.text_color)

    # Body (lines 2+)
    if len(lines) > 1:
        body_text = "\n".join(lines[1:])
        body_y = offset_y + config.title_size * 2  # matches shell script spacing
        draw.text((offset_x, body_y), body_text, font=body_font, fill=config.text_color)

    return img


def apply_logo(
    img: Image.Image,
    logo: Image.Image,
    position: str,
    margin_x: int,
    margin_y: int,
) -> Image.Image:
    """Paste *logo* onto *img* at the given gravity position with margins.

    Positions: SW (bottom-left), SE (bottom-right), NW (top-left), NE (top-right).
    """
    pos = position.upper()
    if pos == "SW":
        x = margin_x
        y = img.height - logo.height - margin_y
    elif pos == "SE":
        x = img.width - logo.width - margin_x
        y = img.height - logo.height - margin_y
    elif pos == "NW":
        x = margin_x
        y = margin_y
    elif pos == "NE":
        x = img.width - logo.width - margin_x
        y = margin_y
    else:
        raise ValueError(f"Ungültige Logo-Position: {position!r}. Erlaubt: SW, SE, NW, NE")

    # Ensure logo has alpha for proper compositing
    if logo.mode != "RGBA":
        logo = logo.convert("RGBA")

    img.paste(logo, (x, y), logo)
    return img


# ---------------------------------------------------------------------------
# Per-image processing
# ---------------------------------------------------------------------------


def _output_paths(source_file: Path, source_folder: Path) -> dict[str, Path]:
    """Compute the three output paths for a source image (matching shell script naming)."""
    paths: dict[str, Path] = {}
    for label, width in RESOLUTIONS.items():
        folder = source_folder / f"watermarked-{width}px"
        # Shell script naming: <original-filename>-<width>px.jpg
        out_name = f"{source_file.name}-{width}px.jpg"
        paths[label] = folder / out_name
    return paths


def _save_jpeg(img: Image.Image, path: Path, quality: int) -> None:
    """Save *img* as JPEG with metadata stripped."""
    # Convert to RGB if needed (e.g. RGBA source)
    if img.mode in ("RGBA", "P", "LA"):
        img = img.convert("RGB")
    elif img.mode != "RGB":
        img = img.convert("RGB")

    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(str(path), "JPEG", quality=quality, optimize=True)


def _resize_and_save(
    img_6k: Image.Image, target_width: int, output_path: Path, quality: int
) -> None:
    """Resize the 6k master to *target_width* and save."""
    resized = resize_to_width(img_6k, target_width)
    _save_jpeg(resized, output_path, quality)


def process_single_image(
    image_path: Path,
    config: Config,
    logo: Image.Image,
    counter: int,
) -> bool:
    """Process one image: resize to 6k → text → logo → save 6k/4k/2k.

    Returns True on success, False on error.
    """
    out = _output_paths(image_path, config.source_folder)

    # --- Skip check ---
    if config.skip_existing and all(p.is_file() for p in out.values()):
        print(f"  SKIP FILE - File exists: >{image_path.name}<")
        return True

    print(f"{counter} PROCESSING: >{image_path.name}<")

    try:
        img = Image.open(image_path)
        img.load()  # force load so we can detect errors early
    except Exception as exc:
        print(f"  Error: Konnte '{image_path.name}' nicht laden: {exc}", file=sys.stderr)
        return False

    # --- 1) Resize to 6000 px width ---
    img_6k = resize_to_width(img, BASE_WIDTH)
    img.close()
    print(f"  WIDTH: {img_6k.width}")

    # Ensure RGB for drawing
    if img_6k.mode != "RGB":
        img_6k = img_6k.convert("RGB")

    # --- 2) Text overlay ---
    txt_path = image_path.with_suffix(".txt")
    print("  Text Imprint")
    img_6k = apply_text_overlay(img_6k, txt_path, config)

    # --- 3) Logo watermark ---
    margin_x = img_6k.width // 50
    print(f"  Adding Watermark {config.logo_position}")
    img_6k = apply_logo(img_6k, logo, config.logo_position, margin_x, OFFSET_Y)

    # --- 4) Save 6k ---
    _save_jpeg(img_6k, out["6k"], config.jpeg_quality)

    # --- 5) Resize & save 4k + 2k in parallel ---
    print("  4k resizing")
    print("  2k resizing")

    with ThreadPoolExecutor(max_workers=min(2, config.workers)) as pool:
        fut_4k = pool.submit(
            _resize_and_save, img_6k, RESOLUTIONS["4k"], out["4k"], config.jpeg_quality
        )
        fut_2k = pool.submit(
            _resize_and_save, img_6k, RESOLUTIONS["2k"], out["2k"], config.jpeg_quality
        )
        # Wait and propagate exceptions
        fut_4k.result()
        fut_2k.result()

    return True


# ---------------------------------------------------------------------------
# CLI & main
# ---------------------------------------------------------------------------


def _find_default_logo(script_dir: Path) -> Path:
    """Locate the default Sternwarte logo relative to the repository root."""
    # script lives in python/, repo root is one level up
    repo_root = script_dir.parent
    candidates = [
        repo_root / "watermark-images" / "Sternwarte-Wasserzeichen_1680x580px.png",
        script_dir / "watermark-images" / "Sternwarte-Wasserzeichen_1680x580px.png",
        script_dir.parent / "watermark-images" / "Sternwarte-Wasserzeichen_1680x580px.png",
    ]
    for c in candidates:
        if c.is_file():
            return c
    return candidates[0]  # will fail later with a clear error


def parse_args(argv: list[str] | None = None) -> Config:
    """Parse CLI arguments and return a Config."""
    script_dir = Path(__file__).resolve().parent

    parser = argparse.ArgumentParser(
        prog="watermarker_v2.py",
        description="Cross-platform image watermarking & resizing (Pillow-based).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Beispiele:\n"
            "  python watermarker_v2.py ./fotos/\n"
            "  python watermarker_v2.py ./fotos/ --logo ./my-logo.png --logo-position SE\n"
            "  python watermarker_v2.py ./fotos/ --title-font 'Georgia' --title-size 60\n"
        ),
    )
    parser.add_argument("source_folder", type=Path, help="Ordner mit Quellbildern")
    parser.add_argument(
        "--logo",
        type=Path,
        default=None,
        help="Wasserzeichen-Logo PNG (Standard: Sternwarte-Wasserzeichen_1680x580px.png)",
    )
    parser.add_argument(
        "--logo-position",
        choices=["SW", "SE", "NW", "NE"],
        default="SW",
        help="Position des Logos (Standard: SW = unten-links)",
    )
    parser.add_argument(
        "--title-font", default="Times New Roman", help="Font für Überschrift (Standard: Times New Roman)"
    )
    parser.add_argument("--title-size", type=int, default=50, help="Schriftgröße Überschrift in px (Standard: 50)")
    parser.add_argument("--body-font", default="Arial", help="Font für Fließtext (Standard: Arial)")
    parser.add_argument("--body-size", type=int, default=16, help="Schriftgröße Fließtext in px (Standard: 16)")
    parser.add_argument("--text-color", default="#808080", help="Textfarbe als Hex (Standard: #808080)")
    parser.add_argument("--jpeg-quality", type=int, default=85, help="JPEG-Qualität 1-100 (Standard: 85)")
    parser.add_argument("--no-skip", action="store_true", help="Bereits vorhandene Dateien überschreiben")
    parser.add_argument(
        "--workers",
        type=int,
        default=2,
        help="Parallele Worker für Resize (Standard: 2)",
    )

    args = parser.parse_args(argv)

    # Resolve source folder
    source = args.source_folder.resolve()
    if not source.is_dir():
        parser.error(f"Quellordner nicht gefunden: {source}")

    # Resolve logo
    logo_path: Path
    if args.logo is not None:
        logo_path = args.logo.resolve()
    else:
        logo_path = _find_default_logo(script_dir)
    if not logo_path.is_file():
        parser.error(f"Logo nicht gefunden: {logo_path}")

    # Resolve fonts
    title_font_path = resolve_font(args.title_font, script_dir)
    body_font_path = resolve_font(args.body_font, script_dir)

    return Config(
        source_folder=source,
        logo_path=logo_path,
        logo_position=args.logo_position,
        title_font_path=title_font_path,
        title_size=args.title_size,
        body_font_path=body_font_path,
        body_size=args.body_size,
        text_color=args.text_color,
        jpeg_quality=args.jpeg_quality,
        skip_existing=not args.no_skip,
        workers=args.workers,
    )


def main(argv: list[str] | None = None) -> int:
    """Entry point."""
    config = parse_args(argv)

    print("=" * 60)
    print("watermarker_v2.py")
    print("=" * 60)
    print(f"Source:        {config.source_folder}")
    print(f"Logo:          {config.logo_path}")
    print(f"Logo-Position: {config.logo_position}")
    print(f"Title-Font:    {config.title_font_path}  ({config.title_size}px)")
    print(f"Body-Font:     {config.body_font_path}  ({config.body_size}px)")
    print(f"Text-Color:    {config.text_color}")
    print(f"JPEG-Quality:  {config.jpeg_quality}")
    print(f"Skip existing: {config.skip_existing}")
    if not _HEIF_AVAILABLE:
        print("Info: pillow-heif nicht installiert — HEIC-Dateien werden übersprungen.")
    print("=" * 60)
    print()

    # --- Create output folders ---
    for width in RESOLUTIONS.values():
        folder = config.source_folder / f"watermarked-{width}px"
        folder.mkdir(parents=True, exist_ok=True)
        print(f"{folder} exists -> OK")

    # --- Load logo once ---
    try:
        logo = Image.open(config.logo_path)
        logo.load()
        if logo.mode != "RGBA":
            logo = logo.convert("RGBA")
    except Exception as exc:
        print(f"Error: Logo konnte nicht geladen werden: {exc}", file=sys.stderr)
        return 1

    # --- Collect images ---
    images: list[Path] = sorted(
        f
        for f in config.source_folder.iterdir()
        if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
    )

    if not images:
        print("Keine Bilder gefunden.")
        return 0

    # --- Process ---
    before = time.monotonic()
    success_count = 0
    error_count = 0

    for idx, img_path in enumerate(images, start=1):
        # Skip HEIC if not supported
        if img_path.suffix.lower() in {".heic", ".heif"} and not _HEIF_AVAILABLE:
            print(f"{idx} SKIP (HEIC nicht unterstützt): >{img_path.name}<")
            continue

        ok = process_single_image(img_path, config, logo, idx)
        if ok:
            success_count += 1
        else:
            error_count += 1

    logo.close()

    # --- Timing ---
    elapsed = int(time.monotonic() - before)
    result_line = f"elapsed time: {elapsed} seconds"
    print()
    print(result_line)
    print(f"Processed: {success_count}, Errors: {error_count}")

    timing_file = config.source_folder / "script_execution_time.txt"
    timing_file.write_text(result_line + "\n", encoding="utf-8")

    return 1 if error_count > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())
