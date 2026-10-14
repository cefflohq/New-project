# Cefflo "Cef-flo" variations V01-V10 (round 2) -- original synthesis only, no samples.
# Every one keeps the two-beat "Cef-flo" idea, but each uses a different
# instrument model AND a different rhythm/interval so they are clearly apart.
import os, subprocess, wave
import numpy as np

SR = 48000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
N = lambda m: 440 * 2 ** ((m - 69) / 12)
rng = np.random.default_rng(11)


def T(d): return np.arange(int(d * SR)) / SR
def att(t, a=0.002): return np.minimum(1, t / a)


# ---------- instrument models (all very different) ----------
def sine_whistle(f, d, f_to=None):            # pure whistle, can glide
    t = T(d); fr = np.full(len(t), f) if f_to is None else f * (f_to / f) ** np.minimum(1, t / 0.08)
    ph = 2 * np.pi * np.cumsum(fr) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 6 * t)
    return np.sin(ph * vib) * att(t, 0.01) * np.exp(-t * 4)

def pluck(f, d):                                # Karplus-Strong string
    n = int(d * SR); p = int(SR / f); buf = rng.uniform(-1, 1, p); out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]; buf[i % p] = 0.996 * 0.5 * (buf[i % p] + buf[(i + 1) % p])
    return out

def epiano(f, d):                               # FM electric piano (Rhodes-ish)
    t = T(d); e = np.exp(-t * 5)
    return np.sin(2 * np.pi * f * t + 1.8 * np.exp(-t * 9) * np.sin(2 * np.pi * f * t)) * e * att(t)

def steel_drum(f, d):
    t = T(d)
    return sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * k) for r, a, k in
               ((1, 1, 6), (2, 0.6, 8), (3, 0.3, 10), (1.5, 0.25, 12))) * att(t, 0.004)

def music_box(f, d):
    t = T(d)
    return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 5.04 * t) * np.exp(-t * 30)) * np.exp(-t * 7) * att(t, 0.001)

def kalimba(f, d):
    t = T(d)
    return (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 6.2 * t) * np.exp(-t * 60)) * np.exp(-t * 9) * att(t, 0.001)

def vibes(f, d):                                # vibraphone with tremolo
    t = T(d); trem = 0.75 + 0.25 * np.sin(2 * np.pi * 5.5 * t)
    return (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 15)) * np.exp(-t * 3) * trem * att(t)

def square_lead(f, d):                          # clean 8-bit lead, filtered
    t = T(d); s = np.sign(np.sin(2 * np.pi * f * t))
    s = np.convolve(s, np.ones(6) / 6, mode="same")
    return s * np.where(t < d * 0.8, 1, np.exp(-(t - d * 0.8) * 40)) * att(t, 0.003) * 0.6

def synth_pluck(f, d):                          # saw with closing low-pass
    t = T(d); s = 2 * ((f * t) % 1) - 1; out = np.zeros_like(s); y = 0
    cut = 0.6 * np.exp(-t * 18) + 0.03
    for i in range(len(s)): y += cut[i] * (s[i] - y); out[i] = y
    return out * np.exp(-t * 6) * att(t)

def harp_octave(f, d):                          # note + its octave, harp-like
    return 0.7 * pluck(f, d) + 0.4 * pluck(f * 2, d)


def mix(parts, total):
    out = np.zeros(int(total * SR))
    for t0, g, s in parts:
        i = int(t0 * SR); out[i:i + len(s)] += g * s[: len(out) - i]
    k = int(0.06 * SR); out[-k:] *= np.linspace(1, 0, k) ** 2
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


# ---------- the 10 variations ----------
# 1 Whistle: "Cef" short, "flo" slides UP into its note (glide)
save("cefflo_v01_whistle_glide", mix([(0, .8, sine_whistle(N(88), .15)), (.15, 1, sine_whistle(N(88), .55, N(95)))], .75))
# 2 Guitar-like pluck, flo an octave DOWN (deep answer)
save("cefflo_v02_string_pluck_down", mix([(0, 1, pluck(N(86), .4)), (.14, 1, pluck(N(74), .7))], .85))
# 3 Electric piano, warm major sixth up, played twice
save("cefflo_v03_epiano_double", mix([(0, .8, epiano(N(81), .3)), (.13, 1, epiano(N(87), .5)),
                                     (.42, .8, epiano(N(81), .3)), (.55, 1, epiano(N(87), .6))], 1.1))
# 4 Steel drum, tropical, flo a fourth up
save("cefflo_v04_steel_drum", mix([(0, .9, steel_drum(N(79), .35)), (.16, 1, steel_drum(N(84), .6))], .8))
# 5 Music box, very high, small step up
save("cefflo_v05_music_box", mix([(0, .9, music_box(N(93), .4)), (.2, 1, music_box(N(95), .8))], 1.0))
# 6 Kalimba, Cef twice quick then flo ("ce-cef-flo")
save("cefflo_v06_kalimba_triplet", mix([(0, .7, kalimba(N(84), .2)), (.08, .8, kalimba(N(84), .2)),
                                       (.2, 1, kalimba(N(91), .6))], .8))
# 7 Vibraphone with tremolo, slow, falling fifth (calm)
save("cefflo_v07_vibes_calm", mix([(0, .9, vibes(N(88), .5)), (.25, 1, vibes(N(81), .9))], 1.15))
# 8 8-bit square lead, game-style, octave up
save("cefflo_v08_8bit_octave", mix([(0, 1, square_lead(N(84), .09)), (.1, 1, square_lead(N(96), .22))], .4))
# 9 Synth pluck with filter sweep, modern app feel
save("cefflo_v09_synth_pluck", mix([(0, .9, synth_pluck(N(79), .3)), (.12, 1, synth_pluck(N(86), .5))], .7))
# 10 Harp with octaves, long "flo" ringing
save("cefflo_v10_harp_ring", mix([(0, .8, harp_octave(N(76), .4)), (.18, 1, harp_octave(N(83), 1.0))], 1.2))
