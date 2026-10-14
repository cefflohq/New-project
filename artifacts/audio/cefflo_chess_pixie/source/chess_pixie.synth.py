# Cefflo "Cef-flo" in two styles -- original synthesis only, no samples.
#   chess: wooden piece-on-board clicks (two taps = Cef-flo)
#   pixie: fairy sparkle / twinkle (two shimmering notes = Cef-flo)
import os, subprocess, wave
import numpy as np

SR = 48000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
N = lambda m: 440 * 2 ** ((m - 69) / 12)
rng = np.random.default_rng(5)
T = lambda d: np.arange(int(d * SR)) / SR


def bp_noise(d, f, q, decay):
    """Resonant band-passed noise burst (two-pole resonator)."""
    x = rng.uniform(-1, 1, int(d * SR)) * np.exp(-T(d) * 900)
    r = np.exp(-np.pi * f / q / SR); c = 2 * r * np.cos(2 * np.pi * f / SR)
    y = np.zeros_like(x)
    for i in range(2, len(x)):
        y[i] = x[i] + c * y[i - 1] - r * r * y[i - 2]
    return y * np.exp(-T(d) * decay)


def wood(f, d=0.18, body=1.0, decay=38):
    """Chess piece on a wooden board: knock + tuned wood modes."""
    t = T(d)
    modes = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * decay * k)
                for r, a, k in ((1, 1, 1), (2.57, .45, 1.6), (4.2, .2, 2.4)))
    return body * modes * np.minimum(1, t / 0.0005) + 0.35 * bp_noise(d, f * 2.2, 6, decay * 1.5)


def sparkle(f, d, n=14, spread=1.0, seed=0):
    """Pixie dust: many tiny high glints scattered around one note."""
    r = np.random.default_rng(seed); out = np.zeros(int(d * SR))
    for _ in range(n):
        t0 = r.uniform(0, d * 0.5 * spread); ff = f * 2 ** r.choice([0, 1, 1, 2]) * r.uniform(.995, 1.005)
        s = np.sin(2 * np.pi * ff * T(0.25)) * np.exp(-T(0.25) * 25) * r.uniform(.15, .4)
        i = int(t0 * SR); out[i:i + len(s)] += s[: len(out) - i]
    return out


def chime(f, d, decay=4):
    t = T(d)
    return (np.sin(2 * np.pi * f * t) + .3 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 12)
            + .12 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 20)) * np.exp(-t * decay) * np.minimum(1, t / .002)


def gliss(f1, f2, d, steps=8):
    """Fairy harp run from f1 up to f2."""
    out = np.zeros(int((d + .4) * SR))
    for k, m in enumerate(np.linspace(f1, f2, steps)):
        s = chime(N(m), .4, 9) * .35; i = int(k * d / steps * SR); out[i:i + len(s)] += s
    return out


def mix(parts, total):
    out = np.zeros(int(total * SR))
    for t0, g, s in parts:
        i = int(t0 * SR); out[i:i + len(s)] += g * s[: len(out) - i]
    k = int(.05 * SR); out[-k:] *= np.linspace(1, 0, k) ** 2
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


# ---------- CHESS ----------
save("cefflo_chess_01_move",        mix([(0, .8, wood(N(79))), (.11, 1, wood(N(84)))], .35))           # tok-TOK, naik
save("cefflo_chess_02_capture",     mix([(0, 1, wood(N(81), body=1.2)), (.07, 1, wood(N(74), .25, 1.3, 28))], .4))  # capture: dua kepingan berlaga
save("cefflo_chess_03_high_click",  mix([(0, .9, wood(N(91), .12, 1, 55)), (.1, 1, wood(N(96), .14, 1, 50))], .3))  # klik tinggi kecil
save("cefflo_chess_04_check",       mix([(0, .9, wood(N(79))), (.11, .9, wood(N(84))), (.11, .5, chime(N(96), .5, 7))], .65))  # gerak + "ting" amaran
save("cefflo_chess_05_slide_place", mix([(0, .25, bp_noise(.12, 3500, 2, 25)), (.1, .8, wood(N(76))), (.2, 1, wood(N(83)))], .45))  # seret lalu letak

# ---------- PIXIE ----------
save("cefflo_pixie_01_twinkle",     mix([(0, .8, chime(N(91), .5, 8)), (.13, 1, chime(N(96), .8, 5)), (.1, .6, sparkle(N(96), .7, seed=1))], .9))
save("cefflo_pixie_02_dust",        mix([(0, .5, sparkle(N(88), .4, 10, seed=2)), (.05, .8, chime(N(88), .4, 10)),
                                         (.17, 1, chime(N(95), .7, 5)), (.17, .6, sparkle(N(95), .7, 16, seed=3))], .9))
save("cefflo_pixie_03_wand_up",     mix([(0, 1, gliss(84, 96, .22)), (.24, 1, chime(N(100), .7, 5)), (.24, .5, sparkle(N(100), .6, seed=4))], 1.0))
save("cefflo_pixie_04_bells_down",  mix([(0, 1, chime(N(98), .5, 7)), (.14, 1, chime(N(93), .8, 4)), (.14, .5, sparkle(N(93), .8, 12, seed=5))], 1.0))
save("cefflo_pixie_05_fairy_double", mix([(0, .8, chime(N(93), .3, 12)), (.1, 1, chime(N(97), .4, 9)),
                                          (.32, .8, chime(N(93), .3, 12)), (.42, 1, chime(N(100), .7, 5)),
                                          (.42, .6, sparkle(N(100), .7, 18, seed=6))], 1.1))

# ---------- PIXIE 01 VARIATIONS (Founder pick: pixie_01_twinkle = G6 -> C7, gap .13) ----------
def twinkle(name, m1, m2, gap=.13, dust=.6, n=14, d1=8, d2=5, seed=1, total=.9, pre_dust=0, pairs=1, rep=.38):
    parts = []
    for k in range(pairs):
        t0 = k * rep
        if pre_dust: parts.append((t0, pre_dust, sparkle(N(m1), .3, 8, seed=seed + 10)))
        parts += [(t0, .8, chime(N(m1), .5, d1)), (t0 + gap, 1, chime(N(m2), .8, d2))]
        if dust: parts.append((t0 + gap - .03, dust, sparkle(N(m2), .7, n, seed=seed + k)))
    save(name, mix(parts, total))

twinkle("cefflo_pixie_01a_higher",       93, 98)                          # A6 -> D7, lebih tinggi
twinkle("cefflo_pixie_01b_quicker",      91, 96, gap=.09, total=.8)       # lebih rapat, lebih snappy
twinkle("cefflo_pixie_01c_more_dust",    91, 96, dust=.9, n=26, seed=7)   # kilauan lebih banyak
twinkle("cefflo_pixie_01d_clean",        91, 96, dust=.25, n=6, seed=8)   # kilauan sikit, lebih bersih
twinkle("cefflo_pixie_01e_wide_jump",    89, 98, seed=9)                  # F6 -> D7, lompatan besar
twinkle("cefflo_pixie_01f_short_ring",   91, 96, d1=12, d2=10, total=.6)  # gema pendek
twinkle("cefflo_pixie_01g_long_ring",    91, 96, d2=2.8, total=1.3)       # gema panjang, lebih magical
twinkle("cefflo_pixie_01h_dust_intro",   91, 96, pre_dust=.35, seed=11)   # kilauan masuk dulu
twinkle("cefflo_pixie_01i_double",       91, 96, pairs=2, total=1.25, seed=12)  # "Cef-flo, Cef-flo"
twinkle("cefflo_pixie_01j_lower_warm",   86, 91, seed=13)                 # D6 -> G6, lebih hangat
