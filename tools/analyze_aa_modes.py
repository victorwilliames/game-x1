#!/usr/bin/env python3
"""Audit paired frame interval and native GPU measurements for MSAA vs FXAA fullscreen."""
import argparse
import json
import math
from collections import defaultdict
from pathlib import Path
from statistics import mean, median

MODES = ("full", "msaa2x", "msaa4x", "no_fxaa")
SCENARIOS = ("idle", "movement", "kiting", "combat", "camera")
PAIRS = (
    ("full", "msaa2x", "Full custom FXAA versus MSAA 2x"),
    ("full", "msaa4x", "Full custom FXAA versus MSAA 4x"),
    ("msaa4x", "msaa2x", "Incremental cost of MSAA 4x"),
    ("msaa2x", "no_fxaa", "MSAA 2x cost vs no AA"),
    ("msaa4x", "no_fxaa", "MSAA 4x cost vs no AA"),
)

def audit(path: Path):
    document = json.loads(path.read_text(encoding="utf8"))
    info = document["info"]
    recs = document["results"]
    runs = int(info.get("runs", 3))
    expected = len(MODES) * len(SCENARIOS) * runs
    if len(recs) != expected or set(info["configs"]) != set(MODES):
        raise ValueError(f"{path}: incomplete/unexpected run; expected {expected} records")
    grouped = defaultdict(dict)
    for rec in recs:
        mode, scenario, run = rec["config"], rec["scenario"], rec["run"]
        if mode not in MODES or scenario not in SCENARIOS or not (0 <= run < runs):
            raise ValueError(f"Unknown configuration/record: {rec}")
        ft = rec["frame_ms_mean"]
        if not isinstance(ft, (float, int)) or not math.isfinite(ft) or ft <= 0:
            raise ValueError("Invalid frametime")
        key = (scenario, run)
        if mode in grouped[key]:
            raise ValueError(f"Duplicate mode {mode} at {key}")
        grouped[key][mode] = rec
    if len(grouped) != len(SCENARIOS) * runs or any(len(row) != len(MODES) for row in grouped.values()):
        raise ValueError("Missing paired scenario/run")
    print(f"\n=== {path} | {info.get('platform')} / {info.get('gpu')} ===")
    for mode in MODES:
        avg = mean(row[mode]["frame_ms_mean"] for row in grouped.values())
        print(f"{mode:18s} {avg:7.3f} ms; equivalent FPS {1000/avg:7.1f}")
    print("\nPaired differences: positive = first mode slower")
    for mode_a, mode_b, label in PAIRS:
        diffs = [row[mode_a]["frame_ms_mean"] - row[mode_b]["frame_ms_mean"] for row in grouped.values()]
        print(f"{mode_a} - {mode_b}: mean {mean(diffs):+.3f} ms, median {median(diffs):+.3f}, positive {sum(x>0 for x in diffs)}/{len(diffs)} ({label})")
        gpu = [row[mode_a]["gpu_ms_mean"] - row[mode_b]["gpu_ms_mean"] for row in grouped.values()
               if row[mode_a].get("gpu_available") and row[mode_b].get("gpu_available")
               and row[mode_a].get("gpu_ms_mean", -1) > 0 and row[mode_b].get("gpu_ms_mean", -1) > 0]
        if gpu:
            print(f"  GPU viewport: mean {mean(gpu):+.3f} ms over {len(gpu)} matched pairs")
    print("WARNING: MSAA 3D only smooths eligible polygon edges; shader grid, alpha/transparency and 2D UI may differ from custom FXAA. No visual parity assumed.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", type=Path)
    args = parser.parse_args()
    for file in args.files:
        audit(file)
