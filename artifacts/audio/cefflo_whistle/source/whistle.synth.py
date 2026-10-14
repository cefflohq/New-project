# Cefflo "Cef-flo" whistle candidates -- original synthesis only, no samples.
# Human-style whistle: near-pure sine + breath noise, pitch scoop, light vibrato.
import os, subprocess, wave
import numpy as np

SR = 48000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
N = lambda m: 440 * 2 ** ((m - 69) / 12)
T = lambda d: np.arange(int(d * SR)) / SR


def whistle(m1, d, m2=None, scoop=0.0, vib=0.0, breath=0.08, rel=0.06, seed=0, glide=0.06):
    """One whistled note. m2: glide target. scoop: semitones to slide up into the note."""
    t = T(d)
    semis = np.full(len(t), float(m1)) - scoop * np.exp(-t / 0.025)
    if m2 is not None:
        semis += (m2 - m1) * np.clip((t - 0.02) / glide, 0, 1) ** 0.7
    semis += vib * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / 0.15, 0, 1)
    f = 440 * 2 ** ((semis - 69) / 12)
    ph = 2 * np.pi * np.cumsum(f) / SR
    tone = np.sin(ph) + 0.06 * np.sin(2 * ph)
    r = np.random.default_rng(seed); nz = r.uniform(-1, 1, len(t))
    nz = np.convolve(nz, np.ones(4) / 4, mode="same")          # soft breath hiss
    e = np.minimum(1, t / 0.015) * np.clip((d - t) / rel, 0, 1)
    return (tone + breath * nz) * e


def mix(parts, total):
    out = np.zeros(int(total * SR))
    for t0, g, s in parts:
        i = int(t0 * SR); out[i:i + len(s)] += g * s[: len(out) - i]
    return out


def save(name, s):
    s = s / np.max(np.abs(s)) * 10 ** (-1 / 20)
    wav = os.path.join(OUT, name + ".wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((s * 32767).astype(np.int16).tobytes())
    for ext, a in (("mp3", ["-b:a", "128k"]), ("ogg", ["-c:a", "libvorbis", "-q:a", "5"])):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, *a, wav[:-3] + ext], check=True)
    print(name, f"{len(s)/SR:.2f}s")


W = whistle
save("cefflo_whistle_01_up",           mix([(0, .9, W(88, .12)), (.15, 1, W(93, .35, vib=.15))], .55))                 # dua siulan naik
save("cefflo_whistle_02_down",         mix([(0, 1, W(93, .12)), (.15, 1, W(88, .38, vib=.15))], .58))                  # dua siulan turun
save("cefflo_whistle_03_slide_up",     mix([(0, .9, W(86, .12)), (.15, 1, W(86, .4, 93, glide=.12))], .6))              # "flo" meluncur naik
save("cefflo_whistle_04_wolf",         mix([(0, 1, W(84, .2, 96, glide=.15)), (.25, 1, W(96, .4, 86, glide=.3))], .7))  # siulan "fuit-fiuu"
save("cefflo_whistle_05_bird",         mix([(0, .9, W(96, .07, scoop=3)), (.09, .9, W(96, .07, scoop=3)),
                                            (.2, 1, W(100, .22, scoop=4))], .5))                                       # macam burung
save("cefflo_whistle_06_scoop",        mix([(0, .9, W(88, .13, scoop=4)), (.16, 1, W(93, .38, scoop=5, vib=.12))], .6)) # gaya orang bersiul
save("cefflo_whistle_07_double",       mix([(0, .9, W(88, .1)), (.13, 1, W(93, .18)), (.38, .9, W(88, .1)), (.51, 1, W(95, .35, vib=.15))], .9))  # "Cef-flo, Cef-flo"
save("cefflo_whistle_08_pure_high",    mix([(0, .9, W(93, .12, breath=0)), (.15, 1, W(98, .35, breath=0))], .55))       # tanpa nafas, sangat bersih
save("cefflo_whistle_09_breathy_soft", mix([(0, .9, W(84, .15, breath=.25, seed=3)), (.18, 1, W(88, .4, breath=.25, seed=4, vib=.2))], .65))  # lembut, banyak nafas
save("cefflo_whistle_10_trill",        mix([(0, .9, W(88, .12)), (.15, 1, W(93, .4, vib=1.0))], .6))                   # "flo" bergetar (trill)
