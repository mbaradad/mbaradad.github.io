#!/usr/bin/env python3
"""Download PLACID frames and create a 2x2 grid GIF."""

import urllib.request
import io
from PIL import Image

BASE_URL = "https://gemmact.github.io/placid/static/videos/frames"
TEST_IDS = [7, 2, 9, 3]   # pick 4 from: 7,2,5,1,11,9,6,3,8
N_FRAMES = 33
CELL_SIZE = 256   # each cell in the 2x2 grid
FPS = 12
PAUSE_FRAMES = round(0.8 * FPS)  # 800ms pause at endpoints

def fetch_frame(test_id, frame_num):
    url = f"{BASE_URL}/test_{test_id}/frame_{frame_num:04d}.jpg"
    with urllib.request.urlopen(url) as resp:
        return Image.open(io.BytesIO(resp.read())).convert("RGB")

def make_grid(frames):
    """frames: list of 4 PIL Images -> 2x2 composite."""
    resized = [f.resize((CELL_SIZE, CELL_SIZE), Image.LANCZOS) for f in frames]
    grid = Image.new("RGB", (CELL_SIZE * 2, CELL_SIZE * 2))
    positions = [(0, 0), (CELL_SIZE, 0), (0, CELL_SIZE), (CELL_SIZE, CELL_SIZE)]
    for img, pos in zip(resized, positions):
        grid.paste(img, pos)
    return grid

print("Downloading frames...")
all_frames = {}
for tid in TEST_IDS:
    all_frames[tid] = []
    for i in range(1, N_FRAMES + 1):
        if i % 5 == 0:
            print(f"  test_{tid}: frame {i}/{N_FRAMES}")
        all_frames[tid].append(fetch_frame(tid, i))

# Build ping-pong sequence
fwd = list(range(N_FRAMES))       # indices 0..32
seq = fwd + [fwd[-1]] * PAUSE_FRAMES + fwd[::-1] + [fwd[0]] * PAUSE_FRAMES

print("Building grid frames...")
grid_frames = []
durations = []
for idx in seq:
    cells = [all_frames[tid][idx] for tid in TEST_IDS]
    grid_frames.append(make_grid(cells))
    durations.append(int(1000 / FPS))

# Extend pause durations at endpoints
pause_ms = 800
for i in range(N_FRAMES, N_FRAMES + PAUSE_FRAMES):
    durations[i] = pause_ms // PAUSE_FRAMES
for i in range(N_FRAMES + PAUSE_FRAMES + N_FRAMES, N_FRAMES + PAUSE_FRAMES + N_FRAMES + PAUSE_FRAMES):
    durations[i] = pause_ms // PAUSE_FRAMES

out_path = "snapshot.gif"
print(f"Saving {out_path}...")
grid_frames[0].save(
    out_path,
    save_all=True,
    append_images=grid_frames[1:],
    duration=durations,
    loop=0,
    optimize=False,
)
print("Done!")
