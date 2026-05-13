#!/bin/bash
shopt -s nullglob

BASE_DIR="${1:-.}"

rm -f "$BASE_DIR"/watermarked-1680px/*.jpg
rm -f "$BASE_DIR"/watermarked-4000px/*.jpg
rm -f "$BASE_DIR"/watermarked-6000px/*.jpg