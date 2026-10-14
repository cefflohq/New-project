# Cefflo "Cef-flo" ring-out notification candidates -- original synthesis only, no samples.
# A notification, not a tune: exactly two strikes (Cef, flo), unhurried, then the
# instrument rings out naturally to 3 s. Ten different premium-sounding bodies.
import os, subprocess, wave
import numpy as np

SR = 48000
DUR = 3.0
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
N = lambda m: 440 * 2 ** ((m - 69) / 12)
T = lambda d: np.arange(int(d * SR)) / SR
rng = np.random.default_rng(33)


def att(t, a): return np.minimum(1, t / a)

def fconv(x, ir):
    n = len(x) + len(ir); m = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(ir, m), m)[:len(x)]

def lp(x, a):
    y = np.zeros_like(x); v = 0.0
    for i in range(len(x)): v += a * (x[i] - v); y[i] = v
    return y

def hall(x, rt=2.2, wet=.35, bright=.25):
    t = T(rt); ir = rng.uniform(-1, 1, len(t)) * np.exp(-t * 6.9 / rt)
    ir = lp(ir, bright); ir[: int(.012 * SR)] = 0            # pre-delay
    w = fconv(x, ir); w *= np.max(np.abs(x)) / (np.max(np.abs(w)) + 1e-9)
    return x + wet * w

# ---------------- render ----------------
def render(name, events, rt=2.2, wet=.35, bright=.25):
    out = np.zeros(int(DUR*SR))
    for t0, g, fn, m, d in events:
        s = g * fn(N(m) if m is not None else 0, min(d, DUR - t0)); i = int(t0*SR); out[i:i+len(s)] += s[:len(out)-i]
    out = hall(out, rt, wet, bright)
    out *= np.clip((DUR - T(DUR)) / .35, 0, 1) ** 1.5           # gentle 0.35 s fade to silence
    out = out / np.max(np.abs(out)) * 10 ** (-1/20)
    wav = os.path.join(OUT, name + ".wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((out*32767).astype(np.int16).tobytes())
    for ext, a in (("mp3", ["-b:a", "160k"]), ("ogg", ["-c:a", "libvorbis", "-q:a", "6"])):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, *a, wav[:-3] + ext], check=True)
    print(name, f"{len(out)/SR:.2f}s")


# ---------------- struck bodies (each a different material) ----------------
def partials(spec, f, d, a=.002):
    t = T(d); return sum(g*np.sin(2*np.pi*f*r*t)*np.exp(-t*k) for r, g, k in spec) * att(t, a)

TUBULAR   = ((1, 1, 1.1), (2.76, .5, 1.6), (5.4, .25, 2.5), (8.93, .1, 4))           # orchestral tubular bell
CRYSTAL   = ((1, 1, 1.3), (2.32, .3, 2.5), (4.25, .12, 4))                           # cut-crystal glass
TEMPLE    = ((1, 1, .9), (1.007, .8, .9), (2.4, .35, 1.8), (3.9, .15, 3))           # small temple bell, slow beat
FORK      = ((1, 1, .8), (6.2, .08, 20))                                             # tuning fork: almost pure
CELESTE   = ((1, 1, 1.6), (3, .25, 4), (4, .1, 6))
STEELTONG = ((1, 1, 1.2), (3.9, .3, 5), (6.7, .08, 9))                               # steel tongue drum
GLASSBOWL = ((1, 1, .7), (2.71, .45, 1.2), (5.1, .12, 2.5))

def strike(spec, a=.002): return lambda f, d: partials(spec, f, d, a)

def vibes_motor(f, d):                                    # vibraphone with slow motor tremolo
    t = T(d); return partials(((1, 1, 1.0), (4, .3, 4), (10, .05, 10)), f, d) * (.7 + .3*np.sin(2*np.pi*4*t))

def glass_rub(f, d):                                      # glass harmonica: soft swell, long sustain
    t = T(d); return (np.sin(2*np.pi*f*t) + .25*np.sin(4*np.pi*f*t)) * att(t, .09) * np.exp(-t*1.0)

def fm_bell(f, d):                                        # luxury FM bell (DX-style)
    t = T(d); return np.sin(2*np.pi*f*t + 2.5*np.exp(-t*2.5)*np.sin(2*np.pi*f*3.5*t)) * np.exp(-t*1.2) * att(t, .002)

def cefflo(name, voice, m1, m2, gap, g1=.8, rt=2.2, wet=.35, bright=.25):
    render(name, [(0, g1, voice, m1, 3), (gap, 1, voice, m2, 3)], rt, wet, bright)

cefflo("cefflo_ring_01_tubular_bell",  strike(TUBULAR),   79, 86, .40, rt=2.6)     # G5 -> D6
cefflo("cefflo_ring_02_crystal",       strike(CRYSTAL),   88, 95, .32)             # E6 -> B6
cefflo("cefflo_ring_03_temple_bell",   strike(TEMPLE),    81, 76, .45, rt=2.8)     # A5 -> E5, turun
cefflo("cefflo_ring_04_tuning_fork",   strike(FORK),      86, 93, .38, wet=.25)    # D6 -> A6, sangat tulen
cefflo("cefflo_ring_05_vibraphone",    vibes_motor,       84, 91, .36)             # C6 -> G6
cefflo("cefflo_ring_06_glass_harmonica", glass_rub,       88, 93, .42, wet=.4)     # E6 -> A6, lembut
cefflo("cefflo_ring_07_fm_bell",       fm_bell,           86, 90, .34)             # D6 -> F#6 (signature notes)
cefflo("cefflo_ring_08_steel_tongue",  strike(STEELTONG, .004), 81, 88, .38)      # A5 -> E6
cefflo("cefflo_ring_09_glass_bowl",    strike(GLASSBOWL, .006), 83, 90, .45, rt=2.8)  # B5 -> F#6
cefflo("cefflo_ring_10_celeste_high",  strike(CELESTE),   93, 98, .30)             # A6 -> D7
