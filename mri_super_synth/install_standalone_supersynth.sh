#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Create a minimal standalone SuperSynth installation without full FreeSurfer.

Usage:
  install_standalone_supersynth.sh --dest /absolute/path/to/standalone [--venv /absolute/path/to/venv] [--download-model]

Options:
  --dest            Destination directory to use as FREESURFER_HOME (required)
  --venv            Optional Python virtual environment path to create/update
  --download-model  Download SuperSynth_August_2025.pth into DEST/models
  --help            Show this help

The standalone layout created is:
  DEST/
    FreeSurferColorLUT.txt
    models/SuperSynth_August_2025.pth      (if --download-model)
    python/packages/SuperSynth/...
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEST=""
VENV_PATH=""
DOWNLOAD_MODEL="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)
      DEST="${2:-}"
      shift 2
      ;;
    --venv)
      VENV_PATH="${2:-}"
      shift 2
      ;;
    --download-model)
      DOWNLOAD_MODEL="1"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${DEST}" ]]; then
  echo "error: --dest is required" >&2
  usage
  exit 1
fi

if [[ "${DEST}" != /* ]]; then
  echo "error: --dest must be an absolute path" >&2
  exit 1
fi

mkdir -p "${DEST}/python/packages" "${DEST}/models"

cp -R "${REPO_ROOT}/mri_super_synth/SuperSynth" "${DEST}/python/packages/"
cp "${REPO_ROOT}/distribution/FreeSurferColorLUT.txt" "${DEST}/FreeSurferColorLUT.txt"

if [[ "${DOWNLOAD_MODEL}" == "1" ]]; then
  MODEL_URL="https://ftp.nmr.mgh.harvard.edu/pub/dist/lcnpublic/dist/SuperSynth_Iglesias_2025/SuperSynth_August_2025.pth"
  curl -fL "${MODEL_URL}" -o "${DEST}/models/SuperSynth_August_2025.pth"
fi

if [[ -n "${VENV_PATH}" ]]; then
  if [[ "${VENV_PATH}" != /* ]]; then
    echo "error: --venv must be an absolute path" >&2
    exit 1
  fi
  python3 -m venv "${VENV_PATH}"
  "${VENV_PATH}/bin/python" -m pip install --upgrade pip
  "${VENV_PATH}/bin/python" -m pip install torch numpy scipy nibabel
fi

cat <<EOF
Done.

Next:
  export FREESURFER_HOME="${DEST}"
  ${VENV_PATH:+source "${VENV_PATH}/bin/activate"}
  python "${DEST}/python/packages/SuperSynth/scripts/inference.py" --help

Example run (Apple Silicon CPU):
  python "${DEST}/python/packages/SuperSynth/scripts/inference.py" \\
    --i /absolute/path/to/input.mgz \\
    --o /absolute/path/to/output_dir \\
    --mode invivo \\
    --model_file "${DEST}/models/SuperSynth_August_2025.pth" \\
    --device cpu
EOF
