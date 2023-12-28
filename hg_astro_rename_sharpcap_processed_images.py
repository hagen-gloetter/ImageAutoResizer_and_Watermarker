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

import os
import shutil

root_folder_path = "."  # Setze hier den Pfad zum Basisordner ein

def rename_and_move_files(root_folder):
    for root, dirs, files in os.walk(root_folder):
        for filename in files:
            file=filename
            folder_names = root.split(os.path.sep)
            if len(folder_names) > 1:
                folder_name = folder_names[1]  # Der Name des ersten Unterordners
#                if filename.startswith("Stack_"):
#                if file.startswith('Stack_') and (file.endswith('.jpg') or file.endswith('.png') or file.endswith('.txt')):
                if file.startswith('Stack_') and (file.endswith('.jpg') or file.endswith('.png') or file.endswith('.txt')):
                    
                    src = os.path.join(root, filename)
                    dst = os.path.join(root, f"{folder_name}-{filename}")
                    target=os.path.join(root_folder, folder_name)


                    print(f"=========================== ")
                    print(f"folder_name: {folder_name} ")
                    print(f"folder_name: {folder_name} ")
                    print(f"src: {src} ")
                    print(f"dst {dst}")
                    print(f"target: {target} ")
                    try:
                        os.rename(src, dst)
                        shutil.move(dst, target)
                    except:
                        print(f"Error target exists: {target} ")

if __name__ == "__main__":
    rename_and_move_files(root_folder_path)

import os

root_folder_path = "."  # Setze hier den Pfad zum Basisordner ein


