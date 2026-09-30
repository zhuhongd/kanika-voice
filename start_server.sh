#!/usr/bin/env bash
# Kanika's voice as an HTTP server on Linux: GPT-SoVITS api_v2.
#
#   GSV_HOME=/path/to/GPT-SoVITS ./start_server.sh [host] [port]
#
# Run from the Python environment GPT-SoVITS was installed into (its install.sh
# sets one up). Untested on Linux so far - the Windows path is the tested one.
set -euo pipefail

GSV="${GSV_HOME:?set GSV_HOME to your GPT-SoVITS folder}"
HOST="${1:-127.0.0.1}"
PORT="${2:-9880}"

# A missing weight file does not stop the server - it silently loads the
# generic pretrained voice instead. Check first.
for f in GPT_weights_v2Pro/kanika-e15.ckpt SoVITS_weights_v2Pro/kanika_e8_s288.pth \
         GPT_SoVITS/configs/tts_infer_kanika.yaml voices/kanika/refs/conversational.wav; do
    [ -e "$GSV/$f" ] || { echo "missing $GSV/$f - unzip kanika-voice.zip into $GSV first"; exit 1; }
done

cd "$GSV"
echo "Kanika voice server on http://$HOST:$PORT"
PYTHONIOENCODING=utf-8 exec python api_v2.py -a "$HOST" -p "$PORT" -c GPT_SoVITS/configs/tts_infer_kanika.yaml
