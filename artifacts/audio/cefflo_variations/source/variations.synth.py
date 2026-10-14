# Cefflo "Cef-flo" variations V01-V10 -- original synthesis only (no samples), engine from shared/sounds/cefflo-signature.synth.py.
import math, wave, array, random, sys
SR = 48000
TAU = 2 * math.pi

def blank(d): return [0.0] * int(d * SR)

def env_ad(t, a, d):           # linear attack, exponential decay
    return (t / a if t < a else math.exp(-(t - a) * d))

def add_fm(buf, t0, f, dur, g, ratio, index, idecay, decay, attack=0.004, glide=None):
    """FM bell/glass tone. glide=(f_from, seconds) slides into f."""
    s0 = int(t0 * SR); n = int(dur * SR); ph = 0.0
    for i in range(n):
        if s0 + i >= len(buf): break
        t = i / SR
        if glide and t < glide[1]:
            k = t / glide[1]; k = 1 - (1 - k) ** 3
            fi = glide[0] * (f / glide[0]) ** k
        else:
            fi = f
        ph += TAU * fi / SR
        mod = index * math.exp(-idecay * t) * math.sin(ph * ratio)
        buf[s0 + i] += g * env_ad(t, attack, decay) * math.sin(ph + mod)

def add_partials(buf, t0, f, dur, g, partials, attack=0.003):
    s0 = int(t0 * SR); n = int(dur * SR)
    for i in range(n):
        if s0 + i >= len(buf): break
        t = i / SR; v = 0.0
        for r, a, d in partials:
            v += a * math.exp(-d * t) * math.sin(TAU * f * r * t)
        buf[s0 + i] += g * min(1.0, t / attack) * v

def add_tick(buf, t0, g, dur=0.006, seed=7):
    """Crisp transient: high-passed noise burst (first difference)."""
    rnd = random.Random(seed); s0 = int(t0 * SR); prev = 0.0
    for i in range(int(dur * SR)):
        x = rnd.uniform(-1, 1); hp = x - prev; prev = x
        buf[s0 + i] += g * hp * math.exp(-i / SR / 0.0015)

def finish(buf, name, fade=0.10):
    n = len(buf); fl = int(fade * SR)
    for k in range(fl): buf[n - fl + k] *= (1 - k / fl) ** 2
    peak = max(abs(x) for x in buf); tgt = 10 ** (-1 / 20)
    buf = [x / peak * tgt for x in buf]
    rms = math.sqrt(sum(x * x for x in buf) / n)
    pcm = array.array('h', (int(max(-1, min(1, x)) * 32767) for x in buf))
    with wave.open(name, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    print(f"{name}: {n/SR:.2f}s peak -1.0 dBFS rms {20*math.log10(rms):.1f} dBFS")

# "Cef-flo, Cef-flo": two beats (Cef = short accent, flo = slightly longer),

import os, subprocess
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
N = lambda m: 440 * 2 ** ((m - 69) / 12)

CEF = [(1, 1.0, 13), (2.0, 0.45, 20), (3.0, 0.18, 30)]
FLO = [(1, 1.0, 8.0), (2.0, 0.38, 13), (3.0, 0.14, 20)]
FLO_END = [(1, 1.0, 6.0), (2.0, 0.35, 11), (3.0, 0.12, 18)]
CRYSTAL = [(1, 1.0, 9.0), (4.0, 0.22, 25)]
MARIMBA = [(1, 1.0, 16), (4.0, 0.3, 40), (10.0, 0.05, 60)]

def beat(b, t0, f, dur, g, voice, last, short):
    if voice == 'bell':
        add_partials(b, t0, f, dur, g, CEF if short else (FLO_END if last else FLO))
    elif voice == 'glass':
        add_fm(b, t0, f, dur, g, 3.5, 1.1, 25 if short else 18, 13 if short else (6 if last else 8), attack=0.002)
    elif voice == 'crisp':
        add_tick(b, t0, 0.13, seed=int(f) % 97)
        add_partials(b, t0 + 0.002, f, dur, g, CEF if short else (FLO_END if last else FLO))
    elif voice == 'crystal':
        add_partials(b, t0, f, dur, g, CRYSTAL)
    elif voice == 'marimba':
        add_partials(b, t0, f, dur, g, MARIMBA if short else [(1, 1.0, 9), (4.0, 0.25, 30)])
    elif voice == 'chime':
        add_fm(b, t0, f, dur, g, 2.0, 1.6, 12, 12 if short else (5 if last else 7), attack=0.002)

def cefflo(name, cef, flo, voice, beat_gap=0.13, repeat=0.40, pairs=2, length=None, flo2=None):
    """cef/flo are MIDI notes; flo2 lets the second pair answer on a different note."""
    starts = [k * repeat for k in range(pairs)]
    length = length or (starts[-1] + beat_gap + 0.45)
    b = blank(length)
    for k, t0 in enumerate(starts):
        last = k == pairs - 1
        f2 = flo2 if (last and flo2 and pairs > 1) else flo
        beat(b, t0, N(cef), 0.30, 0.70, voice, last, True)
        beat(b, t0 + beat_gap, N(f2), length - t0 - beat_gap, 0.90, voice, last, False)
    wav = os.path.join(OUT, name + ".wav")
    finish(b, wav, fade=0.08)
    for ext, args in (("mp3", ["-b:a", "128k"]), ("ogg", ["-c:a", "libvorbis", "-q:a", "5"])):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, *args, wav[:-3] + ext], check=True)

# Reference: approved v1.2.0 = D6 -> F#6, glass, two pairs.
cefflo('cefflo_v01_glass_up_fourth',    86, 91, 'glass')                    # D6 -> G6
cefflo('cefflo_v02_bell_up_fifth',      84, 91, 'bell')                     # C6 -> G6
cefflo('cefflo_v03_crystal_octave',     86, 98, 'crystal')                  # D6 -> D7, very high
cefflo('cefflo_v04_glass_down_third',   93, 89, 'glass')                    # A6 -> F6, turun
cefflo('cefflo_v05_chime_single',       86, 90, 'chime', pairs=1, length=0.7)  # sekali sahaja
cefflo('cefflo_v06_bell_answer',        86, 90, 'bell', flo2=93)            # pair 2 naik lagi: F#6 -> A6
cefflo('cefflo_v07_crisp_fast',         88, 93, 'crisp', beat_gap=0.09, repeat=0.28)  # cepat
cefflo('cefflo_v08_marimba_up',         81, 88, 'marimba')                  # A5 -> E6, kayu lembut
cefflo('cefflo_v09_glass_answer_down',  89, 93, 'glass', flo2=86)           # naik, kemudian tutup turun
cefflo('cefflo_v10_crystal_slow_high',  91, 96, 'crystal', beat_gap=0.18, repeat=0.50)  # G6 -> C7, perlahan
