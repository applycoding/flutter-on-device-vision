# Model weights

The `.tflite` files that belong in this folder are downloaded by
`tool/download_models.sh`. They are gitignored because each file is several
megabytes.

- `ssd_mobilenet_v1_coco.tflite` (COCO SSD MobileNet V1, quantized, 300 input)
- `efficientdet_lite0.tflite` (EfficientDet-Lite0, 320 input)

Run the script before a device build. GitHub Actions runs it before the
Android debug APK job. Unit and widget tests use a fake detector and do not
need the files.
