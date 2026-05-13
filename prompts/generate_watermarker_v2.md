# Prompt: Generate watermarker_v2.py

Write a complete, production-ready Python 3.10+ script called `watermarker_v2.py` that replicates and improves the functionality of the existing `imageAutoResizer_and_Watermarker.sh` bash script. The script must produce **identical visual output** on **macOS, Windows, and Ubuntu** using only **Pillow** (no ImageMagick dependency).

---

## CLI Interface

```
python watermarker_v2.py <source-folder> [options]
```

**Required argument:**
- `source-folder` — path to the folder containing input images

**Optional arguments (with defaults):**
- `--logo <path>` — watermark logo PNG with alpha channel (default: `watermark-images/Sternwarte-Wasserzeichen_1680x580px.png` relative to the script's repository root)
- `--logo-position` — gravity for logo placement (default: `SW` = bottom-left). Accepts: `SW`, `SE`, `NW`, `NE`
- `--title-font <name>` — font name/path for the headline (default: `Times New Roman`)
- `--title-size <int>` — headline font size in px at 6000px base width (default: `50`)
- `--body-font <name>` — font name/path for body text (default: `Arial`)
- `--body-size <int>` — body text font size in px at 6000px base width (default: `16`)
- `--text-color <hex>` — text color as hex string (default: `#808080`)
- `--jpeg-quality <int>` — JPEG output quality 1-100 (default: `85`)
- `--no-skip` — force re-processing even if output files already exist
- `--workers <int>` — number of parallel workers for resizing (default: CPU count)

---

## Processing Pipeline (per image)

1. **Load** the source image.
   - Supported extensions (case-insensitive): `.jpg`, `.jpeg`, `.png`, `.heic`, `.tiff`, `.raw`, `.rw2`
   - For HEIC/HEIF: use `pillow-heif` if available, otherwise skip with a warning.

2. **Resize to 6000px width** (maintain aspect ratio, use `Image.LANCZOS` resampling).
   This is the normalized base canvas — all text and logo rendering happens at this resolution to ensure consistent appearance regardless of original image size.

3. **Text overlay** (only if a `.txt` file with the same base name exists in the source folder):
   - Read the text file as UTF-8.
   - **Line 1** = headline, rendered with `--title-font` at `--title-size` px.
   - **Lines 2+** = body text, rendered with `--body-font` at `--body-size` px.
   - **Position**: Top-left corner (NorthWest gravity).
   - **Margins** (matching the shell script exactly):
     - X-offset = `width / 50` → 120px at 6000px width
     - Y-offset = `100` px (fixed)
   - **Spacing**: Body text starts at Y = `offset_y + (title_size * 2)` below the top edge.
   - **Text color**: `--text-color` (default `#808080`, semi-transparent gray).
   - Render text directly onto the image (no separate bar/background).

4. **Logo watermark**:
   - Load the logo PNG (preserving alpha channel).
   - Paste at `--logo-position` (default: bottom-left / SouthWest).
   - **Margins** (matching the shell script):
     - X-offset = `width / 50` → 120px at 6000px width
     - Y-offset = `100` px (fixed)
   - Use the logo at its **native resolution** (no resizing of the logo itself).
   - Paste using alpha compositing so transparency is preserved.

5. **Save 6000px** output as JPEG with `--jpeg-quality`, strip EXIF metadata.

6. **Resize + save 4000px** output (width=4000, maintain ratio, Lanczos, strip metadata, JPEG quality).

7. **Resize + save 1680px** output (width=1680, maintain ratio, Lanczos, strip metadata, JPEG quality).

---

## Output Folder Structure

Output folders are created **inside the source folder**, matching the shell script exactly:

```
<source-folder>/watermarked-6000px/<original-filename>-6000px.jpg
<source-folder>/watermarked-4000px/<original-filename>-4000px.jpg
<source-folder>/watermarked-1680px/<original-filename>-1680px.jpg
```

- `<original-filename>` = original filename **including** its extension (e.g., `photo.jpg-6000px.jpg`). This matches the bash script behavior.
- Create folders automatically if they don't exist.

---

## Font Handling (Cross-Platform Consistency)

To guarantee **identical output** on all three platforms, the script must use bundled `.ttf` font files:

1. Look for font files in a `fonts/` folder relative to the script's location.
2. Expected font file names:
   - `fonts/times_new_roman.ttf` (or `fonts/TimesNewRoman.ttf`)
   - `fonts/arial.ttf` (or `fonts/Arial.ttf`)
3. If `--title-font` or `--body-font` is a path to a `.ttf` file, use it directly.
4. If it's a font name, search in this order:
   a. `fonts/` folder next to the script (case-insensitive filename match)
   b. System font paths:
      - macOS: `/System/Library/Fonts/Supplemental/`, `/Library/Fonts/`
      - Linux: `/usr/share/fonts/truetype/msttcorefonts/`, `/usr/share/fonts/truetype/`
      - Windows: `C:\Windows\Fonts\`
   c. Pillow default font (with a printed warning)

---

## Skip Logic (Idempotent)

By default, if **all three** output files (6000px, 4000px, 1680px) already exist for an image, skip it and print:
```
SKIP FILE - File exists: >filename<
```
Use `--no-skip` to force re-processing.

---

## Progress Output

Match the shell script's output style:
```
1 PROCESSING: >filename.jpg<
WIDTH: 6000
Adding Watermark SouthWest
Text Imprint
TEXTFILE found: >filename.txt<
4k resizing
2k resizing
```

At the end, print and save elapsed time:
```
elapsed time: 42 seconds
```
Write this to `script_execution_time.txt` in the source folder.

---

## Technical Requirements

- **Python**: 3.10+
- **Dependencies**: `Pillow>=10.0`, optionally `pillow-heif>=0.10.0` for HEIC support
- **No ImageMagick** — pure Python/Pillow implementation
- **Parallel processing**: Use `concurrent.futures.ThreadPoolExecutor` for the 4k and 1680px resize operations (they are I/O-bound)
- **Path handling**: Use `pathlib.Path` throughout. No hardcoded path separators. No `os.path.join`.
- **Encoding**: All file I/O uses UTF-8 explicitly
- **Exit codes**: `0` = success, `1` = error (missing folder, missing logo, invalid args)
- **Error handling**: Don't crash on a single bad image — print error, skip it, continue with next
- **Type hints** on all functions
- **Module docstring** and proper `--help` output via argparse
- **No global mutable state** — pass configuration via dataclass or named tuple

---

## Code Structure

```python
"""watermarker_v2.py — Cross-platform image watermarking and resizing tool."""

@dataclass
class Config:
    """All runtime configuration."""
    source_folder: Path
    logo_path: Path
    logo_position: str
    title_font_path: Path
    title_size: int
    body_font_path: Path
    body_size: int
    text_color: str
    jpeg_quality: int
    skip_existing: bool
    workers: int

RESOLUTIONS = {"6k": 6000, "4k": 4000, "2k": 1680}

def resolve_font(name: str, script_dir: Path) -> Path: ...
def load_image(path: Path) -> Image.Image: ...
def resize_to_width(img: Image.Image, width: int) -> Image.Image: ...
def apply_text_overlay(img: Image.Image, text_path: Path, config: Config) -> Image.Image: ...
def apply_logo(img: Image.Image, logo: Image.Image, position: str, margin_x: int, margin_y: int) -> Image.Image: ...
def process_single_image(image_path: Path, config: Config, logo: Image.Image) -> None: ...
def main() -> int: ...

if __name__ == "__main__":
    raise SystemExit(main())
```

---

## Example Usage

```bash
# Basic usage with defaults (Sternwarte logo, bottom-left, Times New Roman title)
python watermarker_v2.py ./my-photos/

# Custom logo and fonts
python watermarker_v2.py ./my-photos/ --logo ./logos/custom.png --title-font "Georgia" --title-size 60

# Force re-processing
python watermarker_v2.py ./my-photos/ --no-skip

# Change logo position to bottom-right
python watermarker_v2.py ./my-photos/ --logo-position SE
```
