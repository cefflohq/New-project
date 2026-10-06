# Cefflo Signature Notification Sound v1 -- original synthesis (no samples).
# Two short rising bell notes (G5 -> C6) with a soft inharmonic shimmer.
import math, wave, struct, array
SR, DUR = 48000, 0.95
N = int(SR * DUR)
buf = [0.0] * N
# (start s, fundamental Hz, gain)
notes = [(0.000, 783.99, 0.80), (0.115, 1046.50, 1.00)]
# partial ratio, relative amp, decay rate (1/s)
partials = [(1.0, 1.00, 5.5), (2.0, 0.30, 9.0), (2.76, 0.12, 14.0), (4.07, 0.05, 22.0)]
for t0, f0, g in notes:
    s0 = int(t0 * SR)
    for i in range(s0, N):
        t = (i - s0) / SR
        attack = min(1.0, t / 0.004)           # 4 ms soft attack, no click
        v = 0.0
        for r, a, d in partials:
            v += a * math.exp(-d * t) * math.sin(2 * math.pi * f0 * r * t)
        buf[i] += g * attack * v
# gentle fade-out over the last 120 ms -> clean tail
fade = int(0.12 * SR)
for k in range(fade):
    buf[N - fade + k] *= (1 - k / fade) ** 2
peak = max(abs(x) for x in buf)
target = 10 ** (-1.0 / 20)                      # peak -1 dBFS
buf = [x / peak * target for x in buf]
rms = math.sqrt(sum(x * x for x in buf) / N)
print(f"samples={N} dur={DUR}s peak=-1.0dBFS rms={20*math.log10(rms):.1f}dBFS")
pcm = array.array('h', (int(max(-1, min(1, x)) * 32767) for x in buf))
with wave.open('cefflo-signature.wav', 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
