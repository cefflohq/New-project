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

# A -- evolution: rising fifth E5 -> B5 on a glassy FM tone, with a quick
#      upper grace that gives the motion a signature "lift".
a = blank(0.80)
add_fm(a, 0.000, 659.25, 0.30, 0.55, 1.41, 1.6, 18, 9.0)
add_fm(a, 0.085, 987.77, 0.72, 0.85, 1.41, 2.2, 10, 5.2)
add_fm(a, 0.085, 1975.5, 0.25, 0.10, 2.00, 0.5, 20, 16)   # airy octave sheen
finish(a, 'cefflo-signature-A.wav')

# B -- logistics-tech: crisp transient, short bright "ping", then a soft
#      resolving tone a fourth below (D6 -> A5).
b = blank(0.70)
add_tick(b, 0.000, 0.35)
add_fm(b, 0.004, 1174.66, 0.10, 0.55, 3.0, 1.2, 40, 30.0, attack=0.002)
add_partials(b, 0.070, 880.0, 0.62, 0.80, [(1, 1.0, 6.5), (2, 0.22, 11), (3, 0.06, 18)], attack=0.012)
finish(b, 'cefflo-signature-B.wav')

# C -- minimal sonic logo: three mallet notes C6 - G6 - E6 (up a fifth,
#      settle a third), tight rhythm for memorability.
c = blank(0.68)
mallet = [(1, 1.0, 9.0), (3.93, 0.28, 28), (9.2, 0.06, 60)]
add_partials(c, 0.000, 1046.5, 0.40, 0.70, mallet)
add_partials(c, 0.075, 1567.98, 0.40, 0.62, mallet)
add_partials(c, 0.150, 1318.51, 0.53, 0.85, [(1, 1.0, 6.0), (3.93, 0.22, 24), (9.2, 0.05, 55)])
finish(c, 'cefflo-signature-C.wav')

# D -- Cefflo identity: a two-syllable "Cef-flo" figure. A short confident
#      pickup (A5), then a note that glides up into C#6 (bright major third)
#      and blooms with a slow FM shimmer -- a "flow" that resolves upward.
d = blank(0.95)
add_fm(d, 0.000, 880.0, 0.16, 0.60, 2.0, 1.4, 30, 22.0, attack=0.003)
add_fm(d, 0.110, 1108.73, 0.84, 0.90, 1.5, 1.8, 6, 4.6, attack=0.006, glide=(830.6, 0.07))
add_fm(d, 0.110, 2217.46, 0.35, 0.08, 1.0, 0.3, 10, 12, attack=0.01)
finish(d, 'cefflo-signature-D.wav')
