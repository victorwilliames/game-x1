#!/usr/bin/env python3
"""Analyze paired Godot BackBufferCopy/ColorRect benchmark measurements.

This script reports observed differences, not isolated GPU timings.
Use native GPU viewport time only when the Godot benchmark reports it
as available. WebGL frames/RAF are NOT direct GPU measurements.
"""
import argparse
import json
from collections import defaultdict
from pathlib import Path
from statistics import mean, median

MODES = ("pass_only", "crop_draw", "crop_copy", "no_fxaa", "full")
SCENARIOS = ("idle", "movement", "kiting", "combat", "camera")
PAIRS = (
    ("pass_only", "crop_draw", "Draw less; copy still full"),
    ("crop_draw", "crop_copy", "Copy region; draw region"),
    ("crop_copy", "no_fxaa", "Remaining regional pass overhead"),
    ("full", "no_fxaa", "Production postprocess overhead"),
)

def read_results(filepath: Path):
    doc = json.loads(filepath.read_text(encoding="utf-8"))
    info = doc.get("info", {})
    grouped = defaultdict(dict)
    for rec in doc.get("results", []):
        k = (rec.get("scenario"), rec.get("run"))
        mode = rec.get("config")
        if mode not in MODES or k[0] not in SCENARIOS:
            continue
        if mode in grouped[k]:
            raise ValueError(f"Duplicate sample: {mode} {k}")
        if not isinstance(rec.get("frame_ms_mean"), (int, float)) or rec["frame_ms_mean"] <= 0:
            raise ValueError(f"Invalid frame time: {mode} {k}")
        grouped[k][mode] = rec
    return info, grouped

def analyse(filepath: Path):
    info, samples = read_results(filepath)
    print(f"\n=== {filepath} ===")
    print("Platform:", info.get("platform"), "| GPU:", info.get("gpu"))
    print("Runs:", info.get("runs"), "| Scenario:", info.get("scenario_sec"), "s",
          "| Rendering:", info.get("rendering_method"), "| Vsync:", info.get("vsync_mode"))
    if not samples:
        raise ValueError("No valid samples")
    print("\nMedian frame interval per mode (ms), averaged over available runs:")
    for mode in MODES:
        values = [row[mode]["frame_ms_mean"] for row in samples.values() if mode in row]
        if values:
            print(f"  {mode:12} {mean(values):8.3f} ms  ({len(values)} records)")
    print("\nPaired differences in FRAME INTERVAL: positive means the first mode is slower.")
    for a, b, label in PAIRS:
        all_pairs = [(key, row[a], row[b]) for key, row in samples.items() if a in row and b in row]
        if not all_pairs:
            print(f"  {a:12} - {b:12}: no matched records")
            continue
        values = [u["frame_ms_mean"] - v["frame_ms_mean"] for _, u, v in all_pairs]
        wins = sum(1 for x in values if x > 0.0)
        print(f"  {a:12} - {b:12}: mean {mean(values):+.3f} ms; "
              f"median {median(values):+.3f} ms; positives {wins}/{len(values)} ({label})")
        native_gpu = [(u["gpu_ms_mean"], v["gpu_ms_mean"]) for _, u, v in all_pairs
                      if u.get("gpu_available") and v.get("gpu_available")
                      and u.get("gpu_ms_mean", -1) > 0 and v.get("gpu_ms_mean", -1) > 0]
        if native_gpu:
            gpu_values = [x - y for x, y in native_gpu]
            print(f"      GPU viewport (available only): mean {mean(gpu_values):+.3f} ms; "
                  f"matched {len(native_gpu)}/{len(all_pairs)}")
    expected = int(info.get("runs", 3)) * len(SCENARIOS)
    for mode in MODES:
        count = sum(mode in row for row in samples.values())
        if count < expected:
            print(f"WARNING: {mode} only {count}/{expected} records")
    print("\nWARNING: A cropped passthrough test does NOT preserve visual AA."
          " Inspect screenshots and the backbuffer ordering before production changes.")
    print("WARNING: CPU intervals and Web RAF frame durations are not isolated GPU costs."
          " Thermal noise and outliers can dominate short differences.")

def main():
    p = argparse.ArgumentParser()
    p.add_argument("files", nargs="+", type=Path,
                   help="Godot native/web *.json files")
    args = p.parse_args()
    for filename in args.files:
        analyse(filename)

if __name__ == "__main__":
    main()
