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
BUILD_COLRV1_NOFLAGS="${BUILD_COLRV1_NOFLAGS:-0}"

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

colrv1_configs=(colrv1/all.toml)
expected_outputs=("${COLR_INPUT_NAME}")

case "${BUILD_COLRV1_NOFLAGS}" in
  1|true|TRUE|yes|YES)
    colrv1_configs+=(colrv1/noflags.toml)
    expected_outputs+=("${COLR_NOFLAGS_INPUT_NAME}")
    ;;
esac

set +e
nanoemoji --build_dir="${NANOEMOJI_BUILD_DIR}" "${colrv1_configs[@]}"
nanoemoji_status=$?
set -e

if [[ "${nanoemoji_status}" -ne 0 ]]; then
  missing_output=0
  for output in "${expected_outputs[@]}"; do
    if [[ ! -f "${output}" ]]; then
      echo "nanoemoji exited ${nanoemoji_status} and did not produce ${output}." >&2
      missing_output=1
    fi
  done
  if [[ "${missing_output}" -ne 0 ]]; then
    exit "${nanoemoji_status}"
  fi
  echo "nanoemoji exited ${nanoemoji_status}, but all requested COLRv1 fonts were written; continuing to verify outputs." >&2
fi

mv "${COLR_INPUT_NAME}" "${FONT_OUTPUT_DIR}/${COLR_FONT_NAME}"

if [[ -f "${COLR_NOFLAGS_INPUT_NAME}" ]]; then
  mv "${COLR_NOFLAGS_INPUT_NAME}" "${FONT_OUTPUT_DIR}/${COLR_NOFLAGS_FONT_NAME}"
fi

if [[ "${RUN_COLRV1_POSTPROC}" == "1" ]]; then
  python3 colrv1_postproc.py
fi

python3 - <<'PY'
from pathlib import Path
from fontTools.ttLib import TTFont

for font_path in sorted(Path("fonts").glob("Noto-COLRv1*.ttf")):
    font = TTFont(font_path)
    assert "COLR" in font and font["COLR"].version == 1, str(font_path)
    print(f"Verified COLRv1 output: {font_path}")
PY
