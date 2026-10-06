# Cefflo signature candidates A-D -- original synthesis only (no samples).
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
# the pair played twice. Original synthesis only (no samples, no voice).




CEF = [(1, 1.0, 13), (2.0, 0.45, 20), (3.0, 0.18, 30)]       # short, bright
FLO = [(1, 1.0, 8.0), (2.0, 0.38, 13), (3.0, 0.14, 20)]       # a bit longer
FLO_END = [(1, 1.0, 6.0), (2.0, 0.35, 11), (3.0, 0.12, 18)]   # last one rings out
BEAT, REPEAT = 0.13, 0.40                                      # Cef->flo, pair->pair

def cefflo(name, cef_hz, flo_hz, voice='bell', length=0.98):
    b = blank(length)
    for k, t0 in enumerate([0.0, REPEAT]):
        last = k == 1
        if voice == 'bell':
            add_partials(b, t0, cef_hz, 0.30, 0.70, CEF)
            add_partials(b, t0 + BEAT, flo_hz, length - t0 - BEAT, 0.90, FLO_END if last else FLO)
        elif voice == 'glass':
            add_fm(b, t0, cef_hz, 0.30, 0.70, 3.5, 1.1, 25, 13, attack=0.002)
            add_fm(b, t0 + BEAT, flo_hz, length - t0 - BEAT, 0.90, 3.5, 1.1, 18, 6 if last else 8, attack=0.002)
        elif voice == 'crisp':
            add_tick(b, t0, 0.15, seed=3 + k)
            add_partials(b, t0 + 0.002, cef_hz, 0.30, 0.70, CEF)
            add_tick(b, t0 + BEAT, 0.12, seed=5 + k)
            add_partials(b, t0 + BEAT + 0.002, flo_hz, length - t0 - BEAT, 0.90, FLO_END if last else FLO)
    finish(b, name, fade=0.08)

cefflo('cefflo-signature-J.wav', 1318.51, 1760.00, 'bell')    # up a fourth  E6 -> A6
cefflo('cefflo-signature-K.wav', 1567.98, 1318.51, 'bell')    # down a third G6 -> E6
cefflo('cefflo-signature-L.wav', 1046.50, 1567.98, 'bell')    # up a fifth   C6 -> G6
cefflo('cefflo-signature-M.wav', 1174.66, 1479.98, 'glass')   # up a third   D6 -> F#6, glassy
cefflo('cefflo-signature-N.wav', 1046.50, 2093.00, 'crisp')   # up an octave C6 -> C7, crisp
