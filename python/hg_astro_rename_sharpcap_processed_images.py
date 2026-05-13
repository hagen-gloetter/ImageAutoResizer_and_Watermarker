# hagen@gloetter.de 12.2023
# source: https://github.com/hagen-gloetter/ImageAutoResizer_and_Watermarker
# Astro Pictures taken with our Astro Camera ASI ZWO 2600MC-P and SharpCap
# are always stored in a "processed" folder. Moving them out
# and renaming them was always a boring manual process.
# Warning: this script is destructive and there is no undo - so try it on a copy first!
# What is does (destructive):
# 1: renames the images and text files with the name of the parent folder
# 2: moves the images and text files out of the "processed" folder
#
# needed folder structure:
# 2023-12-18-M42-Orion/processed/Stack_29frames_870s.png
# result:
# 2023-12-18-M42-Orion/2023-12-18-M42-Orion-Stack_29frames_870s.png
#
# Usage:  python hg_astro_rename_sharpcap_processed_images.py
# Exit-Codes: 0 = OK; !=0 = Exception beim Umbenennen/Verschieben
"""Astro-Bilder aus SharpCap 'processed'-Unterordnern umbenennen und verschieben."""
from pathlib import Path
import argparse
import shutil
import sys


def is_supported_file(name: str) -> bool:
    """Return True for supported SharpCap output files."""
    lower = name.lower()
    return name.startswith("Stack_") and lower.endswith((".jpg", ".png", ".txt"))


def rename_and_move_files(root_folder: Path) -> int:
    """Rename and move files from */processed to their parent folder.

    Args:
        root_folder: Base folder that contains object folders.

    Returns:
        Number of successfully moved files.
    """
    moved_count = 0
    for processed_dir in root_folder.rglob("processed"):
        if not processed_dir.is_dir():
            continue

        object_dir = processed_dir.parent
        object_name = object_dir.name

        for src in processed_dir.iterdir():
            if not src.is_file() or not is_supported_file(src.name):
                continue

            target_name = f"{object_name}-{src.name}"
            target_path = object_dir / target_name

            print("===========================")
            print(f"object_name: {object_name}")
            print(f"source: {src}")
            print(f"target: {target_path}")

            if target_path.exists():
                print(f"SKIP: target already exists: {target_path}")
                continue

            try:
                shutil.move(str(src), str(target_path))
                moved_count += 1
            except Exception as err:
                print(f"Error moving {src} -> {target_path}: {err}")

    return moved_count


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Rename and move SharpCap processed files to parent object folders"
    )
    parser.add_argument(
        "root",
        nargs="?",
        default=".",
        help="Base folder that contains object folders (default: current directory)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"Error: directory not found: {root}")
        sys.exit(1)

    moved = rename_and_move_files(root)
    print(f"Done. moved_files={moved}")


