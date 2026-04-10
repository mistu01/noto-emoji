#!/usr/bin/env bash

set -euo pipefail
set -x

FONT_NAME="NotoColorEmoji.ttf"
WINDOWS_FONT_NAME="NotoColorEmoji_WindowsCompatible.ttf"
FONT_OUTPUT_DIR="${FONT_OUTPUT_DIR:-fonts}"
EMOJI_SRC_DIR="${EMOJI_SRC_DIR:-png/128}"
BUILD_JOBS="${BUILD_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

python3 size_check.py --png-dir "${EMOJI_SRC_DIR}" --skip-svg

rm -rf build/
rm -f "${FONT_NAME}" "${WINDOWS_FONT_NAME}"
mkdir -p "${FONT_OUTPUT_DIR}"
rm -f "${FONT_OUTPUT_DIR}/${FONT_NAME}"

time make -j "${BUILD_JOBS}" \
  BYPASS_SEQUENCE_CHECK=True \
  EMOJI_SRC_DIR="${EMOJI_SRC_DIR}" \
  FLAGS= \
  "${FONT_NAME}"

mv "${FONT_NAME}" "${FONT_OUTPUT_DIR}/${FONT_NAME}"
