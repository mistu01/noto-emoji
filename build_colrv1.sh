#!/usr/bin/env bash

set -euo pipefail
set -x

CBDT_FONT_NAME="NotoColorEmoji.ttf"
COLR_INPUT_NAME="NotoColorEmoji.ttf"
COLR_NOFLAGS_INPUT_NAME="NotoColorEmoji-noflags.ttf"
COLR_FONT_NAME="Noto-COLRv1.ttf"
COLR_NOFLAGS_FONT_NAME="Noto-COLRv1-noflags.ttf"

FONT_OUTPUT_DIR="${FONT_OUTPUT_DIR:-fonts}"
EMOJI_SRC_DIR="${EMOJI_SRC_DIR:-png/128}"
BUILD_CBDT_DEPENDENCY="${BUILD_CBDT_DEPENDENCY:-1}"
NANOEMOJI_BUILD_DIR="${NANOEMOJI_BUILD_DIR:-build/colrv1}"
RUN_COLRV1_POSTPROC="${RUN_COLRV1_POSTPROC:-1}"

python3 size_check.py --png-dir "${EMOJI_SRC_DIR}" --skip-svg

mkdir -p "${FONT_OUTPUT_DIR}"

if [[ "${BUILD_CBDT_DEPENDENCY}" == "1" || ! -f "${FONT_OUTPUT_DIR}/${CBDT_FONT_NAME}" ]]; then
  FONT_OUTPUT_DIR="${FONT_OUTPUT_DIR}" \
  EMOJI_SRC_DIR="${EMOJI_SRC_DIR}" \
  bash ./full_rebuild.sh
fi

if [[ ! -f "${FONT_OUTPUT_DIR}/${CBDT_FONT_NAME}" ]]; then
  echo "Missing ${FONT_OUTPUT_DIR}/${CBDT_FONT_NAME}; COLRv1 post-processing needs the CBDT font metadata." >&2
  exit 1
fi

python3 colrv1_generate_configs.py

rm -rf "${NANOEMOJI_BUILD_DIR}"
rm -f "${COLR_INPUT_NAME}" "${COLR_NOFLAGS_INPUT_NAME}"
rm -f "${FONT_OUTPUT_DIR}/${COLR_FONT_NAME}" "${FONT_OUTPUT_DIR}/${COLR_NOFLAGS_FONT_NAME}"

nanoemoji \
  --build_dir="${NANOEMOJI_BUILD_DIR}" \
  colrv1/all.toml \
  colrv1/noflags.toml

mv "${COLR_INPUT_NAME}" "${FONT_OUTPUT_DIR}/${COLR_FONT_NAME}"
mv "${COLR_NOFLAGS_INPUT_NAME}" "${FONT_OUTPUT_DIR}/${COLR_NOFLAGS_FONT_NAME}"

if [[ "${RUN_COLRV1_POSTPROC}" == "1" ]]; then
  python3 colrv1_postproc.py
fi

python3 - <<'PY'
from fontTools.ttLib import TTFont

for font_path in ("fonts/Noto-COLRv1.ttf", "fonts/Noto-COLRv1-noflags.ttf"):
    font = TTFont(font_path)
    assert "COLR" in font and font["COLR"].version == 1, font_path
    print(f"Verified COLRv1 output: {font_path}")
PY
