"""Generate 10 unique notification sounds (WAV 44.1 kHz mono, then MP3/OGG via ffmpeg)."""
import os, subprocess, wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..")


def env(n, a=0.005, d=0.25):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / a) * np.exp(-t / d)
    e[-int(0.01 * SR):] *= np.linspace(1, 0, int(0.01 * SR))
    return e


def tone(f, dur, a=0.005, d=0.25, harm=((1, 1.0),), f_end=None):
    n = int(dur * SR)
    t = np.arange(n) / SR
    fr = np.full(n, f) if f_end is None else np.geomspace(f, f_end, n)
    ph = 2 * np.pi * np.cumsum(fr) / SR
    s = sum(g * np.sin(k * ph) for k, g in harm)
    return s * env(n, a, d)


def bell(f, dur, d=0.4):
    # inharmonic partials -> bell / chime colour
    return tone(f, dur, 0.002, d, ((1, 1.0), (2.76, 0.4), (5.4, 0.15), (8.9, 0.05)))


def mallet(f, dur, d=0.18):
    return tone(f, dur, 0.002, d, ((1, 1.0), (4, 0.25), (10, 0.05)))


def soft(f, dur, d=0.35):
    return tone(f, dur, 0.02, d, ((1, 1.0), (2, 0.15)))


def seq(parts, total):
    out = np.zeros(int(total * SR))
    for start, s in parts:
        i = int(start * SR)
        out[i:i + len(s)] += s[: len(out) - i]
    return out


N = lambda m: 440 * 2 ** ((m - 69) / 12)  # midi -> Hz

SOUNDS = {
    # ---- HIGH ----
    "01_high_sparkle": seq([(0.00, bell(N(88), 0.6, 0.25)), (0.07, bell(N(93), 0.6, 0.25)),
                            (0.14, bell(N(100), 0.7, 0.3))], 0.9),
    "02_high_ping": seq([(0.0, bell(N(91), 0.9, 0.45))], 0.9),
    "03_high_double_tap": seq([(0.0, mallet(N(86), 0.25, 0.08)), (0.12, mallet(N(86), 0.35, 0.1))], 0.5),
    # ---- MID ----
    "04_mid_new_order": seq([(0.0, mallet(N(72), 0.4)), (0.11, mallet(N(76), 0.4)),
                             (0.22, mallet(N(79), 0.6, 0.3))], 0.85),
    "05_mid_marimba_pop": seq([(0.0, mallet(N(67), 0.3, 0.1)), (0.09, mallet(N(74), 0.5, 0.2))], 0.6),
    "06_mid_success": seq([(0.0, soft(N(72), 0.5, 0.2)), (0.13, soft(N(79), 0.5, 0.2)),
                           (0.26, bell(N(84), 0.8, 0.4))], 1.1),
    "07_mid_swoosh_rise": seq([(0.0, tone(N(64), 0.35, 0.03, 0.2, ((1, 1), (2, 0.2)), f_end=N(76))),
                               (0.3, bell(N(83), 0.6, 0.3))], 0.9),
    # ---- LOW ----
    "08_low_alert_down": seq([(0.0, soft(N(67), 0.4, 0.25)), (0.18, soft(N(60), 0.6, 0.35))], 0.85),
    "09_low_warning_pulse": seq([(i * 0.2, tone(N(57), 0.16, 0.01, 0.12, ((1, 1), (3, 0.3), (5, 0.1))))
                                 for i in range(3)], 0.75),
    "10_low_error_drop": seq([(0.0, tone(N(62), 0.6, 0.01, 0.3, ((1, 1), (2, 0.3)), f_end=N(48)))], 0.65),
}

for name, s in SOUNDS.items():
    s = s / np.max(np.abs(s)) * 0.85
    pcm = (s * 32767).astype(np.int16)
    wav = os.path.join(OUT, f"jflow_{name}.wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    for ext, args in (("mp3", ["-b:a", "128k"]), ("ogg", ["-c:a", "libvorbis", "-q:a", "5"])):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, *args,
                        wav[:-3] + ext], check=True)
    print(name, f"{len(s)/SR:.2f}s")
