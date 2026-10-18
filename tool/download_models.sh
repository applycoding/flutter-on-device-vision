#!/usr/bin/env bash
# Downloads the two COCO detectors used by the demo.
# Files land in assets/models and are gitignored.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${ROOT}/assets/models"
mkdir -p "${DEST}"

SSD="${DEST}/ssd_mobilenet_v1_coco.tflite"
EFF="${DEST}/efficientdet_lite0.tflite"
SSD_URL="https://storage.googleapis.com/download.tensorflow.org/models/tflite/coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip"
EFF_URL="https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/object_detection/android/lite-model_efficientdet_lite0_detection_metadata_1.tflite"

if [[ ! -s "${SSD}" ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  echo "Downloading SSD MobileNet V1"
  curl -fsSL -o "${TMP}/ssd.zip" "${SSD_URL}"
  unzip -p "${TMP}/ssd.zip" detect.tflite > "${SSD}"
fi

if [[ ! -s "${EFF}" ]]; then
  echo "Downloading EfficientDet-Lite0"
  curl -fsSL -o "${EFF}" "${EFF_URL}"
fi

echo "Models ready:"
ls -lh "${SSD}" "${EFF}"
