import json
import sys
import os

def analyze(filepath):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    results = data.get("results", [])
    info = data.get("info", {})
    print(f"\n=======================================================")
    print(f" ANALYSIS: {os.path.basename(filepath)}")
    print(f" Platform: {info.get('platform')}, Engine: {info.get('engine')}, Web: {info.get('web')}")
    print(f" GPU: {info.get('gpu')}, Runs: {info.get('runs')}, Sec/sc: {info.get('scenario_sec')}")
    print(f"=======================================================\n")

    # Group by (config, scenario)
    by_cfg_sc = {}
    by_cfg = {}

    for r in results:
        cfg = r["config"]
        sc = r["scenario"]
        k = (cfg, sc)
        if k not in by_cfg_sc:
            by_cfg_sc[k] = []
        by_cfg_sc[k].append(r)

        if cfg not in by_cfg:
            by_cfg[cfg] = []
        by_cfg[cfg].append(r)

    scenarios = ["idle", "movement", "kiting", "combat", "camera"]
    configs = ["full", "pass_only", "no_fxaa"]

    print("--- 1. OVERALL AVERAGES PER CONFIGURATION ---")
    cfg_summary = {}
    for cfg in configs:
        if cfg not in by_cfg:
            continue
        items = by_cfg[cfg]
        fps_list = [x["fps_mean"] for x in items]
        ms_list = [x["frame_ms_mean"] for x in items]
        p50_list = [x["frame_ms_p50"] for x in items]
        p95_list = [x["frame_ms_p95"] for x in items]
        p99_list = [x["frame_ms_p99"] for x in items]
        gpu_list = [x["gpu_ms_mean"] for x in items if x.get("gpu_available") and x.get("gpu_ms_mean", -1) > 0]

        cfg_summary[cfg] = {
            "fps": sum(fps_list) / len(fps_list),
            "frame_ms": sum(ms_list) / len(ms_list),
            "p50": sum(p50_list) / len(p50_list),
            "p95": sum(p95_list) / len(p95_list),
            "p99": sum(p99_list) / len(p99_list),
            "gpu_ms": (sum(gpu_list) / len(gpu_list)) if gpu_list else None,
        }
        gpu_str = f", GPU: {cfg_summary[cfg]['gpu_ms']:.2f}ms" if cfg_summary[cfg]['gpu_ms'] else ""
        print(f"  [{cfg:9s}] FPS: {cfg_summary[cfg]['fps']:5.1f} | Frame: {cfg_summary[cfg]['frame_ms']:4.2f}ms | p50: {cfg_summary[cfg]['p50']:4.2f}ms | p95: {cfg_summary[cfg]['p95']:4.2f}ms | p99: {cfg_summary[cfg]['p99']:4.2f}ms{gpu_str}")

    print("\n--- 2. COST BREAKDOWN (OVERALL) ---")
    if "full" in cfg_summary and "pass_only" in cfg_summary and "no_fxaa" in cfg_summary:
        full_ms = cfg_summary["full"]["frame_ms"]
        pass_ms = cfg_summary["pass_only"]["frame_ms"]
        nofx_ms = cfg_summary["no_fxaa"]["frame_ms"]

        filter_cost = full_ms - pass_ms
        composite_cost = pass_ms - nofx_ms
        total_cost = full_ms - nofx_ms

        print(f"  • Total Cost (full vs no_fxaa):                {total_cost:+5.2f} ms ({total_cost/nofx_ms*100:+.1f}%)")
        print(f"  • Screen Copy & Blit Quad (pass_only vs no_fxaa): {composite_cost:+5.2f} ms ({composite_cost/nofx_ms*100:+.1f}%)")
        print(f"  • FXAA Filtering (full vs pass_only):            {filter_cost:+5.2f} ms ({filter_cost/pass_ms*100:+.1f}%)")

        if cfg_summary["full"]["gpu_ms"] and cfg_summary["pass_only"]["gpu_ms"] and cfg_summary["no_fxaa"]["gpu_ms"]:
            g_full = cfg_summary["full"]["gpu_ms"]
            g_pass = cfg_summary["pass_only"]["gpu_ms"]
            g_nofx = cfg_summary["no_fxaa"]["gpu_ms"]
            print(f"  --- GPU Viewport Breakdown ---")
            print(f"  • Total GPU Cost (full vs no_fxaa):            {g_full - g_nofx:+5.2f} ms")
            print(f"  • GPU Screen Copy & Blit (pass_only vs no_fxaa): {g_pass - g_nofx:+5.2f} ms")
            print(f"  • GPU FXAA Filtering (full vs pass_only):        {g_full - g_pass:+5.2f} ms")

    print("\n--- 3. DETAILED PER-SCENARIO BREAKDOWN ---")
    for sc in scenarios:
        print(f"\n  Scenario: {sc.upper()}")
        for cfg in configs:
            k = (cfg, sc)
            if k in by_cfg_sc:
                items = by_cfg_sc[k]
                fps = sum(x["fps_mean"] for x in items) / len(items)
                fms = sum(x["frame_ms_mean"] for x in items) / len(items)
                p50 = sum(x["frame_ms_p50"] for x in items) / len(items)
                p95 = sum(x["frame_ms_p95"] for x in items) / len(items)
                p99 = sum(x["frame_ms_p99"] for x in items) / len(items)
                gpu = [x["gpu_ms_mean"] for x in items if x.get("gpu_available") and x.get("gpu_ms_mean", -1) > 0]
                gpu_s = f", GPU: {sum(gpu)/len(gpu):4.2f}ms" if gpu else ""
                print(f"    {cfg:9s} -> FPS: {fps:5.1f} | Frame: {fms:4.2f}ms | p50: {p50:4.2f}ms | p95: {p95:4.2f}ms{gpu_s}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        for p in sys.argv[1:]:
            analyze(p)
    else:
        analyze("docs/migration/visual/fxaa_cost_native.json")
