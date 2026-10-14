# Cefflo "Cef-flo" premium 3-second candidates -- original synthesis only, no samples.
# Each one opens with the two-beat Cef-flo motif and then lets it bloom: unhurried
# tempo, layered voices, chords and a real-sounding room. Ten different styles.
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

# ---------------- voices ----------------
def celesta(f, d):
    t = T(d); return sum(a*np.sin(2*np.pi*f*r*t)*np.exp(-t*k) for r, a, k in ((1,1,2.2),(2,.35,4),(4,.12,8),(5.93,.05,14))) * att(t,.002)

def string_pad(f, d, a=.5):
    t = T(d); s = sum(2*((f*k*t + p) % 1)-1 for k, p in ((1,0),(1.004,.3),(.996,.6),(2.002,.1)))
    return lp(s/4, .06) * att(t, a) * np.clip((d - t)/.6, 0, 1)

def bonang(f, d):                                           # gamelan gong-chime
    t = T(d); return sum(a*np.sin(2*np.pi*f*r*t)*np.exp(-t*k) for r, a, k in ((1,1,1.6),(1.006,.6,1.6),(2.76,.3,4),(4.1,.12,7))) * att(t,.002)

def saron(f, d):                                            # gamelan metal bar
    t = T(d); return sum(a*np.sin(2*np.pi*f*r*t)*np.exp(-t*k) for r, a, k in ((1,1,3),(2.9,.4,7),(5.6,.15,12))) * att(t,.001)

def handpan(f, d):
    t = T(d); fr = f*(1+.004*np.exp(-t/.03)); ph = 2*np.pi*np.cumsum(fr)/SR
    return (np.sin(ph) + .5*np.sin(2*ph)*np.exp(-t*3) + .25*np.sin(3*ph)*np.exp(-t*5)) * np.exp(-t*1.8) * att(t,.004)

def harp(f, d):
    n = int(d*SR); p = int(SR/f); buf = rng.uniform(-1,1,p); buf = lp(buf, .5); out = np.zeros(n)
    for i in range(n):
        j = i % p; out[i] = buf[j]; buf[j] = .9985*.5*(buf[j] + buf[(j+1) % p])
    return out

def felt_piano(f, d):
    t = T(d); s = sum(a*np.sin(2*np.pi*f*r*t*(1+.0004*r*r))*np.exp(-t*k) for r, a, k in ((1,1,1.4),(2,.5,2.2),(3,.22,3.5),(4,.1,5)))
    return lp(s, .25) * att(t,.006)

def singing_bowl(f, d):
    t = T(d); beat = 1 + .3*np.sin(2*np.pi*3.2*t)
    return (np.sin(2*np.pi*f*t) + .6*np.sin(2*np.pi*f*2.71*t)*np.exp(-t*.8)) * beat * np.exp(-t*.9) * att(t,.01)

def music_box(f, d):
    t = T(d); return (np.sin(2*np.pi*f*t) + .3*np.sin(2*np.pi*f*5.04*t)*np.exp(-t*25) + .15*np.sin(2*np.pi*f*3*t)*np.exp(-t*6)) * np.exp(-t*2.5) * att(t,.001)

def soft_horn(f, d):
    t = T(d); s = sum(np.sin(2*np.pi*f*k*t)*a for k, a in ((1,1),(2,.5),(3,.3),(4,.15)))
    vib = 1 + .01*np.sin(2*np.pi*5*t)*np.clip(t/.4,0,1)
    return s * vib * att(t,.12) * np.clip((d - t)/.4, 0, 1) * .6

def gambus(f, d):                                           # Malay oud-style pluck, bright then woody
    n = int(d*SR); p = int(SR/f); buf = rng.uniform(-1,1,p); out = np.zeros(n)
    for i in range(n):
        j = i % p; out[i] = buf[j]; buf[j] = .997*(.55*buf[j] + .45*buf[(j+1) % p])
    return out

def rhodes(f, d):
    t = T(d); return np.sin(2*np.pi*f*t + 1.4*np.exp(-t*4)*np.sin(2*np.pi*f*t)) * np.exp(-t*1.6) * att(t,.003)

def sub(f, d):
    t = T(d); return np.sin(2*np.pi*f*t) * att(t,.02) * np.exp(-t*1.2)

def shimmer(f, d, n=20, seed=0):
    r = np.random.default_rng(seed); out = np.zeros(int(d*SR))
    for _ in range(n):
        t0 = r.uniform(0, d*.6); s = np.sin(2*np.pi*f*r.choice([2,4])*r.uniform(.997,1.003)*T(.6))*np.exp(-T(.6)*8)*r.uniform(.05,.15)
        i = int(t0*SR); out[i:i+len(s)] += s[:len(out)-i]
    return out

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

C = lambda root, shape: [root + i for i in shape]

# 1 Cinematic: celesta Cef-flo over a slow string swell, motif answered an octave up
render("cefflo_premium_01_cinematic_celesta",
       [(0, .7, celesta, 86, 3), (.28, .9, celesta, 91, 3), (.9, .6, celesta, 98, 2.1), (1.15, .7, celesta, 103, 1.8)]
       + [(0, .22, string_pad, m, 3) for m in C(67, (0, 7, 12, 16))], 2.6, .4)
# 2 Nusantara: gamelan bonang + saron, pelog-like D-Eb-F-A, gong-soft finish
render("cefflo_premium_02_gamelan",
       [(0, .8, bonang, 74, 3), (.32, .9, bonang, 81, 3), (.85, .6, saron, 86, 1.5), (1.1, .6, saron, 87, 1.5),
        (1.35, .7, saron, 89, 1.6), (1.7, .8, bonang, 93, 1.3), (0, .35, bonang, 50, 3)], 1.8, .3)
# 3 Handpan: warm round notes, Cef-flo then a rolling D-kurd arpeggio
render("cefflo_premium_03_handpan",
       [(0, .9, handpan, 74, 3), (.3, 1, handpan, 81, 3), (.85, .55, handpan, 77, 2), (1.05, .55, handpan, 79, 2),
        (1.25, .7, handpan, 81, 1.75), (1.5, .8, handpan, 86, 1.5)], 1.6, .3, .2)
# 4 Harp & air: harp Cef-flo, slow upward glissando, soft pad underneath
render("cefflo_premium_04_harp_glissando",
       [(0, .9, harp, 79, 3), (.3, 1, harp, 86, 2.7)] + [(.8 + k*.09, .5, harp, m, 2.2-k*.09) for k, m in enumerate((86, 88, 91, 93, 95, 98))]
       + [(0, .15, string_pad, m, 3) for m in C(62, (0, 7, 12))], 2.4, .38)
# 5 Felt piano: intimate, unhurried, a resolving major-seventh voicing
render("cefflo_premium_05_felt_piano",
       [(0, .8, felt_piano, 79, 3), (.38, 1, felt_piano, 86, 2.6), (1.0, .45, felt_piano, 67, 2), (1.0, .4, felt_piano, 71, 2),
        (1.0, .4, felt_piano, 74, 2), (1.0, .35, felt_piano, 78, 2), (1.3, .55, felt_piano, 91, 1.7)], 2.0, .32, .18)
# 6 Singing bowl: meditative, two bowls breathing in and out
render("cefflo_premium_06_singing_bowls",
       [(0, .8, singing_bowl, 81, 3), (.45, 1, singing_bowl, 88, 2.55), (0, 1, shimmer, 88, 2.5)], 2.8, .3, .3)
# 7 Music-box lullaby with pad: delicate four-note phrase, Cef-flo twice
render("cefflo_premium_07_music_box_dream",
       [(0, .8, music_box, 91, 3), (.25, 1, music_box, 96, 3), (.75, .8, music_box, 91, 2.3), (1.0, 1, music_box, 98, 2),
        (1.6, .7, music_box, 100, 1.4)] + [(0, .15, string_pad, m, 3) for m in C(72, (0, 4, 7))], 2.5, .4, .3)
# 8 Soft horn fanfare: noble two-note call, gentle brass swell
render("cefflo_premium_08_soft_fanfare",
       [(0, .8, soft_horn, 74, .55), (.45, 1, soft_horn, 81, 2.3), (.45, .6, soft_horn, 77, 2.3), (.45, .5, soft_horn, 69, 2.3),
        (.45, .4, celesta, 93, 2.5)], 2.6, .35, .2)
# 9 Gambus (Malay oud): plucked Cef-flo with a Hijaz-colour answer
render("cefflo_premium_09_gambus",
       [(0, .9, gambus, 74, 3), (.3, 1, gambus, 81, 3), (.85, .6, gambus, 82, 2), (1.05, .6, gambus, 78, 2),
        (1.3, .8, gambus, 81, 1.7), (0, .25, gambus, 62, 3)], 1.6, .25, .3)
# 10 Neo-soul keys: Rhodes Cef-flo over warm sub, lush 9th chord and sparkle
render("cefflo_premium_10_neo_soul_keys",
       [(0, .8, rhodes, 81, 3), (.35, 1, rhodes, 88, 2.65)] + [(.9, .35, rhodes, m, 2.1) for m in (69, 72, 76, 79, 83)]
       + [(.9, .5, sub, 45, 2.1), (1.2, 1, shimmer, 88, 1.8)], 2.0, .3, .22)
