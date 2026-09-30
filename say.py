"""
Speak text in Kanika's voice, via a running GPT-SoVITS api_v2 server.

    python say.py "Hi! Good morning. How are you doing today?"
    python say.py "..." -o hello.wav --ref greeting
    python say.py "..." --server http://gpu-box:9880

Standard library only, so it runs from any Python 3.8+, on any machine that can
reach the server. The server needs the GPU; this script does not.

The reference clip sets tone and energy. Choices are in refs.json; the default,
"conversational", was picked by ear as the most natural for speaking to someone.
"""

import argparse
import io
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
import wave
from pathlib import Path

REFS = json.loads((Path(__file__).parent / "refs.json").read_text(encoding="utf-8"))


def speak(text: str, ref: str = REFS["default"], server: str = "http://127.0.0.1:9880") -> bytes:
    """Return a complete WAV (mono, 32 kHz) of `text` spoken in Kanika's voice."""
    r = REFS["refs"][ref]
    query = {
        "text": text,
        "text_lang": "en",
        # A path on the SERVER, relative to its GPT-SoVITS folder.
        "ref_audio_path": r["wav"],
        # Must match the reference clip word for word. A mismatch does not
        # error - it quietly makes the voice worse.
        "prompt_text": r["text"],
        "prompt_lang": "en",
        "text_split_method": "cut5",    # split long text at punctuation
        "media_type": "wav",
    }
    url = f"{server.rstrip('/')}/tts?{urllib.parse.urlencode(query)}"
    try:
        with urllib.request.urlopen(url, timeout=300) as resp:
            data = resp.read()
    except urllib.error.HTTPError as e:
        raise SystemExit(f"server error {e.code}: {e.read()[:300].decode(errors='replace')}")
    except urllib.error.URLError as e:
        raise SystemExit(f"cannot reach {server} - is start_server running? ({e.reason})")

    with wave.open(io.BytesIO(data)) as w:
        seconds = w.getnframes() / w.getframerate()
    # When synthesis crashes inside the server it still answers 200, with about
    # half a second of silence. This is the only symptom on the client side.
    if seconds < 0.8:
        raise SystemExit(f"server returned {seconds:.1f}s of audio - synthesis failed on the server. "
                         "Check its window for the error.")
    return data


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("text")
    p.add_argument("-o", "--out", default="out.wav")
    p.add_argument("--ref", default=REFS["default"], choices=list(REFS["refs"]))
    p.add_argument("--server", default="http://127.0.0.1:9880")
    a = p.parse_args()

    data = speak(a.text, a.ref, a.server)
    Path(a.out).write_bytes(data)
    with wave.open(io.BytesIO(data)) as w:
        print(f"{a.out}  {w.getnframes() / w.getframerate():.1f}s  (ref: {a.ref})")


if __name__ == "__main__":
    sys.exit(main())
