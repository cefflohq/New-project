# Cefflo "Cef-flo" modern UI candidates -- original synthesis only, no samples.
# Modern app sound palette: soft plucks, bubbles, glassy FM, filtered synth,
# subtle room reverb and echo. Every one keeps the two-beat Cef-flo shape.
import os, subprocess, wave
import numpy as np

SR = 48000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
N = lambda m: 440 * 2 ** ((m - 69) / 12)
T = lambda d: np.arange(int(d * SR)) / SR
rng = np.random.default_rng(21)


def att(t, a=.003): return np.minimum(1, t / a)

def lp(x, a):                                       # one-pole low-pass, a may be array
    a = np.broadcast_to(a, x.shape); y = np.zeros_like(x); v = 0.0
    for i in range(len(x)): v += a[i] * (x[i] - v); y[i] = v
    return y

# ---- voices ----
def soft_pluck(f, d):                               # sine + soft 2nd harmonic, fast decay
    t = T(d); return (np.sin(2*np.pi*f*t) + .2*np.sin(4*np.pi*f*t)*np.exp(-t*30)) * np.exp(-t*9) * att(t)

def bubble(f, d):                                   # pitch drops into note, round "pop"
    t = T(d); fr = f * (1 + .5*np.exp(-t/.012)); ph = 2*np.pi*np.cumsum(fr)/SR
    return np.sin(ph) * np.exp(-t*14) * att(t, .001)

def glass_fm(f, d):
    t = T(d); return np.sin(2*np.pi*f*t + 2.2*np.exp(-t*20)*np.sin(2*np.pi*f*3.0*t)) * np.exp(-t*7) * att(t, .002)

def filt_saw(f, d):                                 # detuned saws, closing filter
    t = T(d); s = sum(2*((f*k*t) % 1)-1 for k in (1, 1.006, .994)) / 3
    return lp(s, .5*np.exp(-t*22)+.02) * np.exp(-t*6) * att(t)

def tap(d=.012):                                    # tiny UI click transient
    x = rng.uniform(-1, 1, int(d*SR)); return np.diff(x, prepend=0) * np.exp(-T(d)/.0015) * .5

def chord_pluck(m, d, shape=(0, 4, 7, 12)):        # future-bass style chord stab
    return sum(filt_saw(N(m+i), d) for i in shape) / len(shape)

def pad_swell(f, d):                                # airy swell into the note
    t = T(d); s = sum(np.sin(2*np.pi*f*k*t) for k in (1, 1.003, .997))/3
    return s * np.minimum(1, t/.12) * np.exp(-np.maximum(0, t-.12)*5)

def rhodes_wobble(f, d):                            # lo-fi keys with tape wobble
    t = T(d); fr = f*(1+.003*np.sin(2*np.pi*4*t)); ph = 2*np.pi*np.cumsum(fr)/SR
    return np.sin(ph + 1.2*np.exp(-t*8)*np.sin(ph)) * np.exp(-t*5) * att(t)

# ---- space ----
def reverb(x, amt=.25, rt=.35):
    ir = rng.uniform(-1, 1, int(rt*SR)) * np.exp(-T(rt)*(6.9/rt)); ir = lp(ir, .35)
    wet = np.convolve(x, ir)[:len(x)]; wet /= (np.max(np.abs(wet)) + 1e-9)
    return x/np.max(np.abs(x)) + amt*wet

def echo(x, dt=.11, fb=.35, n=3):
    y = x.copy(); k = int(dt*SR)
    for j in range(1, n+1): y[j*k:] += (fb**j) * x[:len(x)-j*k]
    return y

def mix(parts, total):
    out = np.zeros(int(total*SR))
    for t0, g, s in parts:
        i = int(t0*SR); out[i:i+len(s)] += g*s[:len(out)-i]
    return out

def save(name, s):
    k = int(.04*SR); s[-k:] *= np.linspace(1, 0, k)**2
    s = s/np.max(np.abs(s)) * 10**(-1/20)
    wav = os.path.join(OUT, name + ".wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((s*32767).astype(np.int16).tobytes())
    for ext, a in (("mp3", ["-b:a", "128k"]), ("ogg", ["-c:a", "libvorbis", "-q:a", "5"])):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, *a, wav[:-3] + ext], check=True)
    print(name, f"{len(s)/SR:.2f}s")


save("cefflo_modern_01_soft_pluck",  reverb(mix([(0, .8, soft_pluck(N(86), .4)), (.12, 1, soft_pluck(N(93), .6))], .8)))
save("cefflo_modern_02_bubble_pop",  reverb(mix([(0, .9, bubble(N(84), .3)), (.11, 1, bubble(N(91), .4))], .6), .15))
save("cefflo_modern_03_glass_echo",  echo(mix([(0, .8, glass_fm(N(88), .4)), (.12, 1, glass_fm(N(95), .5))], 1.0), .13, .3))
save("cefflo_modern_04_tap_tone",    reverb(mix([(0, 1, tap()), (0, .7, soft_pluck(N(88), .3)), (.1, 1, tap()), (.1, 1, soft_pluck(N(95), .5))], .65), .2))
save("cefflo_modern_05_synth_blip",  reverb(mix([(0, .8, filt_saw(N(84), .25)), (.1, 1, filt_saw(N(91), .45))], .7), .2))
save("cefflo_modern_06_chord_stab",  reverb(mix([(0, .8, chord_pluck(79, .25)), (.12, 1, chord_pluck(84, .5))], .8), .3))
save("cefflo_modern_07_airy_swell",  reverb(mix([(0, .7, pad_swell(N(86), .4)), (.2, 1, soft_pluck(N(93), .6)), (.2, .5, pad_swell(N(93), .6))], 1.0), .35, .5))
save("cefflo_modern_08_lofi_keys",   reverb(mix([(0, .8, rhodes_wobble(N(81), .4)), (.13, 1, rhodes_wobble(N(88), .7))], .9), .3))
save("cefflo_modern_09_pingpong",    echo(mix([(0, .8, bubble(N(91), .2)), (.1, 1, soft_pluck(N(96), .4))], .9), .09, .4, 4))
save("cefflo_modern_10_minimal_dot", mix([(0, .7, soft_pluck(N(93), .15)), (.08, 1, soft_pluck(N(98), .3))], .4))
