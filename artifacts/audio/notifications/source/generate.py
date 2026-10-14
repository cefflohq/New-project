"""Generate 10 hard, distinct Jflow notification sounds (WAV 44.1 kHz mono + MP3/OGG via ffmpeg)."""
import os, subprocess, wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..")
rng = np.random.default_rng(7)
N = lambda m: 440 * 2 ** ((m - 69) / 12)  # midi -> Hz


def t_(dur):
    return np.arange(int(dur * SR)) / SR


def env(n, a=0.001, d=0.15, hold=0.0):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / a) * np.where(t < hold, 1.0, np.exp(-(t - hold) / d))
    k = min(n, int(0.005 * SR))
    e[-k:] *= np.linspace(1, 0, k)
    return e


def osc(kind, f, dur, f_end=None):
    n = int(dur * SR)
    fr = np.full(n, f) if f_end is None else np.geomspace(f, f_end, n)
    ph = np.cumsum(fr) / SR
    if kind == "sq":
        return np.sign(np.sin(2 * np.pi * ph))
    if kind == "saw":
        return 2 * (ph % 1) - 1
    if kind == "tri":
        return 2 * np.abs(2 * (ph % 1) - 1) - 1
    return np.sin(2 * np.pi * ph)


def fm(fc, ratio, index, dur, d):
    t = t_(dur)
    e = env(len(t), 0.001, d)
    return np.sin(2 * np.pi * fc * t + index * e * np.sin(2 * np.pi * fc * ratio * t)) * e


def drive(s, k=4.0):
    return np.tanh(k * s) / np.tanh(k)


def noise(dur, d):
    n = int(dur * SR)
    return rng.uniform(-1, 1, n) * env(n, 0.0005, d)


def seq(parts, total):
    out = np.zeros(int(total * SR))
    for start, s in parts:
        i = int(start * SR)
        out[i:i + len(s)] += s[: len(out) - i]
    return out


def kick(dur=0.25):
    return drive(osc("sin", 180, dur, 45) * env(int(dur * SR), 0.001, 0.09), 3)


SOUNDS = {
    # 1 Square-wave double beep, harsh digital (high)
    "01_hard_digital_beep": seq([(0, drive(osc("sq", N(88), 0.09) * env(int(.09 * SR), .001, 1, .08), 2)),
                                 (0.13, drive(osc("sq", N(88), 0.09) * env(int(.09 * SR), .001, 1, .08), 2))], 0.3),
    # 2 FM metal clang (high-mid)
    "02_hard_metal_clang": seq([(0, fm(N(76), 1.41, 9, 0.7, 0.18)), (0, 0.5 * noise(0.03, 0.01))], 0.7),
    # 3 Distorted saw stab chord (mid)
    "03_hard_saw_stab": seq([(0, drive(sum(osc("saw", N(m), 0.22) for m in (60, 67, 72)) / 3
                                       * env(int(.22 * SR), .001, .08), 6))], 0.3),
    # 4 Siren sweep up-down (mid-high)
    "04_hard_siren_sweep": seq([(0, drive(osc("sq", N(72), 0.25, N(84)) * env(int(.25 * SR), .002, 1, .24), 1.5)),
                                (0.25, drive(osc("sq", N(84), 0.25, N(72)) * env(int(.25 * SR), .001, .12), 1.5))], 0.55),
    # 5 Impact: kick + noise crack (low)
    "05_hard_impact_hit": seq([(0, kick(0.35)), (0, 0.6 * noise(0.08, 0.025))], 0.4),
    # 6 Laser zap: fast pitch dive (high -> low)
    "06_hard_laser_zap": seq([(0, drive(osc("sq", N(100), 0.18, N(55)) * env(int(.18 * SR), .001, .07), 2))], 0.22),
    # 7 Arcade trill: rapid 4-note square run up (high)
    "07_hard_arcade_run": seq([(i * 0.05, osc("sq", N(m), 0.05) * env(int(.05 * SR), .001, 1, .045))
                               for i, m in enumerate((72, 76, 79, 84, 88))], 0.3),
    # 8 Buzzer: detuned saws, gritty (low)
    "08_hard_buzzer": seq([(0, drive((osc("saw", N(45), 0.4) + osc("saw", N(45) * 1.03, 0.4))
                                     * env(int(.4 * SR), .002, 1, .36), 5))], 0.42),
    # 9 Triple punch: kick + square pitch hits descending (low-mid)
    "09_hard_triple_punch": seq([(i * 0.11, 0.6 * kick(0.1) + drive(osc("tri", N(m), 0.1) * env(int(.1 * SR), .001, .04), 3))
                                 for i, m in enumerate((67, 62, 55))], 0.4),
    # 10 Glitch stutter: chopped noise + bitcrushed tone (mid)
    "10_hard_glitch": seq([(i * 0.04, (np.round(osc("sq", N(m), 0.03) * 3) / 3 + 0.4 * noise(0.03, 0.01))
                            * env(int(.03 * SR), .0005, 1, .028))
                           for i, m in enumerate((79, 79, 91, 67, 79, 91))], 0.28),
}

for name, s in SOUNDS.items():
    s = s / np.max(np.abs(s)) * 0.95
    pcm = (s * 32767).astype(np.int16)
    wav = os.path.join(OUT, f"jflow_{name}.wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    for ext, args in (("mp3", ["-b:a", "128k"]), ("ogg", ["-c:a", "libvorbis", "-q:a", "5"])):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, *args, wav[:-3] + ext], check=True)
    print(name, f"{len(s)/SR:.2f}s")
