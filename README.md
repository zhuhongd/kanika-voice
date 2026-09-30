# Kanika — voice model

A fine-tuned [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) v2Pro voice of
Kanika. Give it English text, get back a WAV of her saying it. Voice only — no
agent or persona attached; build on it however you like.

```
python say.py "Hi! Good morning. How are you doing today?"   ->  out.wav
```

**Use it only within what Kanika agreed to.** Don't redistribute the weights,
publish generated audio, or present anything it says as a real recording of her.

## What's in this repo, and what isn't

This repo holds only code and docs. Nothing in it can speak. The voice itself is
one file on the **Releases** page, `kanika-voice.zip` (269 MB, private like the
repo):

| | |
|---|---|
| `GPT_weights_v2Pro/kanika-e15.ckpt` | GPT stage — her rhythm, intonation, accent |
| `SoVITS_weights_v2Pro/kanika_e8_s288.pth` | SoVITS stage — the sound of her voice |
| `voices/kanika/refs/*.wav` | five short real clips of her (5–10 s) |
| `GPT_SoVITS/configs/tts_infer_kanika.yaml` | server config pointing at the above |

The reference clips are **not optional**. GPT-SoVITS re-hears a few seconds of
her on every request and imitates it; the weights alone won't produce her voice.

## Requirements

| | |
|---|---|
| OS | Windows 10/11 (tested). Linux should work, untested — see below |
| GPU | NVIDIA with CUDA. Tested on an RTX 4070 Ti (12 GB); the server holds ~2 GB of VRAM |
| GPT-SoVITS | the **v2Pro** package, `GPT-SoVITS-v2pro-20250604.7z` (~7.7 GB) |
| Access | `gh` (GitHub CLI), signed in as an account with access to this repo |

## Setup (Windows)

1. Download `GPT-SoVITS-v2pro-20250604.7z` from the
   [GPT-SoVITS releases](https://github.com/RVC-Boss/GPT-SoVITS/releases) and
   extract it, ideally to `C:\GPT-SoVITS-v2pro-20250604`.
2. `gh auth login` (once).
3. Clone this repo and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File setup.ps1
   # GPT-SoVITS somewhere else?   setup.ps1 -GsvHome "D:\path\to\GPT-SoVITS-v2pro-20250604"
   ```

   It downloads `kanika-voice.zip` and unpacks it into the GPT-SoVITS folder.
   Already have the zip? `setup.ps1 -Zip path\to\kanika-voice.zip`.

## Run it

```
start_server.bat                  # http://127.0.0.1:9880 — leave the window open
python say.py "Your text here."   # -> out.wav
```

The first start takes 15–45 s to load. After that, a sentence takes ~1.5 s to
generate on the tested GPU.

`say.py` needs only the standard library and can run on a different machine
from the server (`--server http://host:9880`). Options: `-o file.wav`,
`--ref <name>`.

## Using it from your own code

The server is GPT-SoVITS's `api_v2`. One endpoint matters: `/tts`, GET or POST.

```python
import requests

REF = {  # from refs.json - the text must match the clip word for word
    "wav": "voices/kanika/refs/conversational.wav",
    "text": "Yeah, all right. If there are no more questions, I think we're good to end. "
            "And I will be sharing these slides and links and everything with you after the meeting today.",
}

r = requests.post("http://127.0.0.1:9880/tts", json={
    "text": "Hi! Good morning. How are you doing today?",
    "text_lang": "en",
    "ref_audio_path": REF["wav"],      # path on the SERVER, relative to its GPT-SoVITS folder
    "prompt_text": REF["text"],
    "prompt_lang": "en",
    "text_split_method": "cut5",       # split long text at punctuation
    "media_type": "wav",
})
open("hello.wav", "wb").write(r.content)   # mono, 32 kHz
```

For long text, stream: add `"streaming_mode": true` and `"media_type": "raw"` and
read the response in chunks — raw 16-bit PCM, mono, 32 kHz. Audio arrives one
sentence at a time, so the first sentence plays while the rest is generated. It
does not make a single sentence faster; for that, send sentences one by one.

### Reference clips

The reference sets tone and energy more than anything else. All five are in
`refs.json`; the ones picked by ear:

| name | | |
|---|---|---|
| `conversational` | **default** | her answering a question — most natural for talking *to* someone |
| `greeting` | good | opening a meeting — brighter, good for hellos |
| `casual` | good | relaxed, mid-explanation |
| `explaining`, `question` | ok | presenting |

### Writing text for her

- **All-caps words are spelled out letter by letter.** `NOW` comes out "N-O-W".
  Write words in normal case; keep caps only for real acronyms (`IPR`, `PPT`).
- Numbers, `$`, `%` are expanded automatically (`$50` → "fifty dollars").
- Short lines (a greeting alone) are the weakest case. A slightly longer
  sentence lands more reliably than a two-word one.
- English only.

## How good it is

Trained on 17 minutes of her from a single Teams recording. Measured on six
sentences she never said:

- **Words:** 15–16 of 16 lines transcribe back word for word (Whisper large-v3).
- **Sounds like her:** speaker similarity 0.79–0.85 on full sentences, against
  0.85 for her own real clips, 0.16 for other people in the same meeting.
- **Pace:** ~3 words/s, the same as her real speech.

Limits:

- **It sounds like a video call**, because the source was one: Teams records at
  16 kHz, so nothing above 8 kHz exists to learn. Slightly muffled, never crisp.
- Short greetings are less consistent than full sentences.
- It occasionally skips a word, more often in long text (a test paragraph lost
  one "First,"). Regenerate if a line matters.

## Things that will bite you

- **A missing weight file doesn't stop the server** — it silently loads the
  generic pretrained voice instead, which sounds like no one in particular.
  `start_server.bat` checks the files first; if you start `api_v2.py` another
  way, check yourself.
- **Start the server with `PYTHONIOENCODING=utf-8`** if its output goes anywhere
  but a console window (a log file, a service). It prints Chinese progress text;
  Windows' default encoding can't, and every request then returns ~0.5 s of
  silence with a 200 status. `start_server.bat` sets it.
- **`/set_gpt_weights` and `/set_sovits_weights` are saved into the config
  file.** Swap weights through the API and the next start loads whatever you
  swapped to. Re-run `setup.ps1` to restore the config.
- **No authentication.** `start_server.bat 0.0.0.0` makes it reachable from the
  network, and anyone who can reach the port can make her voice say anything.
  Put something in front of it before exposing it.
- **One request at a time.** Concurrent requests queue.
- **CPU-only works but is far too slow** for anything interactive: set
  `device: cpu` and `is_half: false` in `tts_infer_kanika.yaml`.

## Linux (untested)

Install GPT-SoVITS from source (its `install.sh`, v2Pro models included), unzip
`kanika-voice.zip` into that folder, then:

```bash
GSV_HOME=/path/to/GPT-SoVITS ./start_server.sh            # or: ./start_server.sh 0.0.0.0 9880
```

## Further training

The training data (her clips and transcripts) isn't included — it was cut from
an internal meeting recording and stays with the original project. To fine-tune
further or retrain, ask Hongda.
