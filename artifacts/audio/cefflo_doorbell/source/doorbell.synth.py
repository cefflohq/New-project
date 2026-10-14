# Cefflo doorbell candidates -- original synthesis only, no samples.
# Classic chime-bar, Westminster, electronic and smart doorbells.

import os, subprocess, wave
import numpy as np

SR = 48000
DUR = 2.6
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


# ---------------- doorbell voices ----------------
def chime_bar(f, d):                      # struck metal tone bar of a mechanical "ding-dong"
    t = T(d); return sum(a*np.sin(2*np.pi*f*r*t)*np.exp(-t*k) for r, a, k in
                         ((1, 1, 1.5), (2.0, .25, 3), (2.76, .35, 4), (5.4, .1, 9))) * att(t, .0015)

def plunger(d=.02):                       # solenoid "thunk" before the bar is hit
    x = rng.uniform(-1, 1, int(d*SR)); return lp(x, .08) * np.exp(-T(d)/.004) * 2

def tubular(f, d):
    t = T(d); return sum(a*np.sin(2*np.pi*f*r*t)*np.exp(-t*k) for r, a, k in
                         ((1, 1, 1.0), (2.76, .5, 1.8), (5.4, .25, 3), (8.93, .1, 5))) * att(t, .002)

def beep(f, d):                           # electronic doorbell tone
    t = T(d); return (np.sin(2*np.pi*f*t) + .3*np.sin(6*np.pi*f*t)) * att(t, .005) * np.clip((d-t)/.03, 0, 1) * .6

def soft_bell(f, d):                      # modern smart-doorbell chime
    t = T(d); return (np.sin(2*np.pi*f*t) + .2*np.sin(4*np.pi*f*t)*np.exp(-t*6)) * np.exp(-t*2.2) * att(t, .004)

def B(name, ev, rt=1.6, wet=.3, bright=.25): render(name, ev, rt, wet, bright)

# 1 Classic ding-dong (E5 -> C5), with the plunger thunk
B("cefflo_doorbell_01_classic_ding_dong", [(0, .4, lambda f, d: plunger(), None, .1), (0, .9, chime_bar, 76, 2.6),
                                           (.55, .4, lambda f, d: plunger(), None, .1), (.55, 1, chime_bar, 72, 2.0)])
# 2 Bright ding-dong, higher (A5 -> F5)
B("cefflo_doorbell_02_bright_ding_dong", [(0, .9, chime_bar, 81, 2.6), (.5, 1, chime_bar, 77, 2.1)])
# 3 Ding-dong-ding (three bars)
B("cefflo_doorbell_03_ding_dong_ding",  [(0, .9, chime_bar, 79, 2.6), (.4, .9, chime_bar, 76, 2.2), (.8, 1, chime_bar, 72, 1.8)])
# 4 Westminster phrase on tubular bells (E-C-D-G)
B("cefflo_doorbell_04_westminster",     [(0, .8, tubular, 76, 2.6), (.42, .8, tubular, 72, 2.2), (.84, .8, tubular, 74, 1.8),
                                           (1.26, 1, tubular, 67, 1.34)], 2.0, .32)
# 5 Electronic doorbell (two-tone beep, played twice)
B("cefflo_doorbell_05_electronic",      [(0, 1, beep, 88, .22), (.25, 1, beep, 84, .3), (.75, 1, beep, 88, .22), (1.0, 1, beep, 84, .3)], .8, .15)
# 6 Smart doorbell (soft ascending chime)
B("cefflo_doorbell_06_smart_chime",     [(0, .8, soft_bell, 79, 2.6), (.18, .85, soft_bell, 83, 2.4), (.36, 1, soft_bell, 86, 2.2)], 1.8, .35)
# 7 Up-down "ding-dong" in the Cefflo signature notes (D6 -> F#6, then back)
B("cefflo_doorbell_07_cefflo_notes",    [(0, .9, chime_bar, 86, 2.6), (.4, 1, chime_bar, 90, 2.2), (.9, .8, chime_bar, 86, 1.7)])
