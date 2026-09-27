# -*- coding: utf-8 -*-
"""Synthesize cute 8-bit-ish SFX wavs into assets/audio/ (stdlib only).

Run from project root:  python tool/gen_sfx.py
"""
import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        w.writeframes(frames)
    print("wrote", path, len(samples) / SR, "s")


def env(i, n, attack=0.01, decay=None):
    """Attack-decay envelope 0..1."""
    t = i / SR
    total = n / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    d = 1.0 - (i / n) if decay is None else max(0.0, 1.0 - t / decay)
    return a * d


def tone(freq, ms, vol=0.5, shape="sine", sweep_to=None):
    n = int(SR * ms / 1000)
    out = []
    phase = 0.0
    for i in range(n):
        f = freq if sweep_to is None else freq + (sweep_to - freq) * i / n
        phase += 2 * math.pi * f / SR
        if shape == "square":
            v = 1.0 if math.sin(phase) >= 0 else -1.0
        elif shape == "tri":
            v = 2 / math.pi * math.asin(math.sin(phase))
        else:
            v = math.sin(phase)
        out.append(v * vol * env(i, n))
    return out


def noise(ms, vol=0.4, lowpass=0.3):
    n = int(SR * ms / 1000)
    out = []
    prev = 0.0
    for i in range(n):
        raw = random.uniform(-1, 1)
        prev = prev + lowpass * (raw - prev)  # 1차 로우패스
        out.append(prev * vol * env(i, n))
    return out


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def mix(a, b, offset_ms=0):
    off = int(SR * offset_ms / 1000)
    n = max(len(a), off + len(b))
    out = [0.0] * n
    for i, v in enumerate(a):
        out[i] += v
    for i, v in enumerate(b):
        out[off + i] += v
    return [max(-1, min(1, v)) for v in out]


random.seed(42)



def peep(ms, f0, f1, f2, vol):
    """병아리 삐약 한 번: f0→f1로 올랐다가 f2로 떨어지는 짧은 지저귐.

    사인파에 약한 2배음을 얹어 새소리처럼 만들고, 잔떨림(비브라토)을 조금 준다.
    끝을 부드럽게(sin²) 닫아 딸깍 소리가 나지 않게 한다.
    """
    n = int(SR * ms / 1000)
    out = []
    phase = 0.0
    for i in range(n):
        x = i / n
        f = f0 + (f1 - f0) * (x / 0.35) if x < 0.35 else f1 + (f2 - f1) * ((x - 0.35) / 0.65)
        f *= 1 + 0.02 * math.sin(2 * math.pi * 38 * i / SR)
        phase += 2 * math.pi * f / SR
        v = math.sin(phase) + 0.25 * math.sin(2 * phase)
        out.append(v / 1.25 * vol * math.sin(math.pi * x) ** 2)
    return out


# 이동: 삐약. 걸음마다 나므로 작고 짧게(90ms) — 날카로운 고음을 피해
# 2.2~2.9kHz에 머문다. (예전엔 노이즈 "쉬익"이었는데 듣기 싫다고 했다)
write_wav("move", peep(90, 2200, 2900, 2000, 0.32))
# 막힘: 벽에 부딪히는 툭. 병아리가 튕기는 연출만 있고 소리가 없어
# 화면과 귀가 따로 놀았다. 이동음보다 낮고 짧게 — 걸음과 헷갈리지 않게.
write_wav("bump", mix(tone(120, 70, 0.42, "tri"), noise(45, 0.22, 0.8)))
# 밀기: 낮은 통통
write_wav("push", tone(220, 110, 0.5, "tri"))
# 미끄럼: 슉— 노이즈 페이드
write_wav("slide", noise(200, 0.35, 0.25))
# 둥지 안착: 딩동
write_wav("nest", concat(tone(880, 90, 0.4), tone(1320, 140, 0.4)))
# 클리어: 상승 아르페지오
arp = tone(523, 120, 0.35)
arp = mix(arp, tone(659, 120, 0.35), 90)
arp = mix(arp, tone(784, 120, 0.35), 180)
arp = mix(arp, tone(1047, 240, 0.4), 270)
write_wav("clear", arp)
# 해금: 반짝 트레몰로
trem = []
for k in range(5):
    trem = mix(trem, tone(1760, 70, 0.3), k * 55) if trem else tone(1760, 70, 0.3)
write_wav("unlock", trem)
# 버튼·문: 클릭
write_wav("button", tone(1000, 45, 0.4, "square"))
# 붕괴: 콰직 노이즈
write_wav("crack", noise(140, 0.55, 0.6))
# 텔레포트: 웅— 스윕
write_wav("teleport", tone(300, 250, 0.4, "sine", sweep_to=900))

print("done")
