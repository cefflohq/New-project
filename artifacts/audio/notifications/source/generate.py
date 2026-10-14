"""Generate 10 clear, high-pitched two-tone ("teng-teng") Jflow notification sounds.

Each sound is two notes. They differ by direction (up/down/same), interval,
gap and timbre. WAV 44.1 kHz mono + MP3/OGG via ffmpeg.
"""
import os, subprocess, wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..")
N = lambda m: 440 * 2 ** ((m - 69) / 12)  # midi -> Hz

# Timbres: (partial ratio, gain, decay multiplier). All clean, no distortion.
TIMBRES = {
    "pure": ((1, 1.0, 1.0),),
    "bell": ((1, 1.0, 1.0), (2.0, 0.35, 0.6), (3.0, 0.12, 0.4)),
    "glass": ((1, 1.0, 1.0), (2.76, 0.25, 0.5), (5.4, 0.08, 0.3)),
    "crystal": ((1, 1.0, 1.0), (4.0, 0.2, 0.35)),
    "chime": ((1, 1.0, 1.0), (2.0, 0.5, 0.8), (4.0, 0.15, 0.5)),
}


def note(f, timbre, dur, decay):
    t = np.arange(int(dur * SR)) / SR
    s = sum(g * np.sin(2 * np.pi * f * r * t) * np.exp(-t / (decay * dm))
            for r, g, dm in TIMBRES[timbre])
    s *= np.minimum(1.0, t / 0.002)  # 2 ms attack, clean click-free onset
    k = int(0.01 * SR)
    s[-k:] *= np.linspace(1, 0, k)
    return s


def two_tone(m1, m2, gap, timbre, decay=0.35):
    dur = 0.6
    a, b = note(N(m1), timbre, dur, decay), note(N(m2), timbre, dur, decay)
    i = int(gap * SR)
    out = np.zeros(i + len(b))
    out[:len(a)] += a
    out[i:i + len(b)] += b
    return out


SOUNDS = {
    #  name                      note1 note2 gap   timbre
    "01_teng_up_bell":        (84, 88, 0.14, "bell"),     # C6 -> E6, naik
    "02_teng_down_bell":      (91, 84, 0.14, "bell"),     # G6 -> C6, turun
    "03_teng_up_fifth_pure":  (88, 95, 0.12, "pure"),     # E6 -> B6, naik lompat
    "04_teng_down_glass":     (96, 89, 0.16, "glass"),    # C7 -> F6, turun
    "05_teng_octave_up":      (81, 93, 0.13, "crystal"),  # A5 -> A6, naik oktaf
    "06_teng_same_double":    (93, 93, 0.11, "glass"),    # A6 x2, ting-ting
    "07_teng_down_step":      (88, 86, 0.15, "chime"),    # E6 -> D6, turun sikit
    "08_teng_up_quick":       (86, 91, 0.08, "crystal"),  # D6 -> G6, cepat
    "09_teng_down_octave":    (95, 83, 0.15, "pure"),     # B6 -> B5, jatuh oktaf
    "10_teng_up_slow_chime":  (83, 90, 0.22, "chime"),    # B5 -> F#6, perlahan
}

for name, (m1, m2, gap, timbre) in SOUNDS.items():
    s = two_tone(m1, m2, gap, timbre)
    s = s / np.max(np.abs(s)) * 0.9
    pcm = (s * 32767).astype(np.int16)
    wav = os.path.join(OUT, f"jflow_{name}.wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    for ext, args in (("mp3", ["-b:a", "160k"]), ("ogg", ["-c:a", "libvorbis", "-q:a", "6"])):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, *args, wav[:-3] + ext], check=True)
    print(name, f"{len(s)/SR:.2f}s")
