#!/usr/bin/env python3
"""
Inspect visual differences between:
- full (production custom FXAA)
- msaa2x (MSAA 2x, no FXAA)
- msaa4x (MSAA 4x, no FXAA)
- no_fxaa (raw 3D, no AA)
"""

from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont

BASE_DIR = Path("docs/migration/visual")

def main():
    img_full = Image.open(BASE_DIR / "aa_fullscreen_full.png").convert("RGB")
    img_m2 = Image.open(BASE_DIR / "aa_fullscreen_msaa2x.png").convert("RGB")
    img_m4 = Image.open(BASE_DIR / "aa_fullscreen_msaa4x.png").convert("RGB")
    img_nofx = Image.open(BASE_DIR / "aa_fullscreen_no_fxaa.png").convert("RGB")

    w, h = img_full.size
    print(f"Image dimensions: {w}x{h}")

    modes = [
        ("FULL (FXAA)", img_full),
        ("MSAA 2X", img_m2),
        ("MSAA 4X", img_m4),
        ("NO_FXAA (Raw 3D)", img_nofx)
    ]

    # 1. 2x2 Grid of full views
    canvas_2x2 = Image.new("RGB", (w * 2, h * 2), (18, 18, 22))
    canvas_2x2.paste(img_full, (0, 0))
    canvas_2x2.paste(img_m2, (w, 0))
    canvas_2x2.paste(img_m4, (0, h))
    canvas_2x2.paste(img_nofx, (w, h))

    d2 = ImageDraw.Draw(canvas_2x2)
    d2.text((20, 20), "MODE: FULL (Production Custom FXAA)", fill=(255, 255, 255))
    d2.text((w + 20, 20), "MODE: MSAA 2X (Hardware 3D Multi-Sampling)", fill=(100, 255, 100))
    d2.text((20, h + 20), "MODE: MSAA 4X (Hardware 3D Multi-Sampling)", fill=(100, 200, 255))
    d2.text((w + 20, h + 20), "MODE: NO_FXAA (Raw Aliased 3D)", fill=(255, 100, 100))

    out_2x2 = BASE_DIR / "aa_modes_visual_comparison.png"
    canvas_2x2.save(out_2x2)
    print(f"Saved 2x2 full comparison to {out_2x2}")

    # Helper function to create 4x zoom strips (4 modes side-by-side)
    def create_zoom_strip(crop_rect, title, filename):
        cw = crop_rect[2] - crop_rect[0]
        ch = crop_rect[3] - crop_rect[1]
        scale = 4
        zw = cw * scale
        zh = ch * scale
        strip = Image.new("RGB", (zw * 4 + 50, zh + 40), (15, 15, 18))
        d = ImageDraw.Draw(strip)
        for i, (mname, img) in enumerate(modes):
            cropped = img.crop(crop_rect).resize((zw, zh), Image.Resampling.NEAREST)
            x_pos = 10 + i * (zw + 10)
            strip.paste(cropped, (x_pos, 30))
            color = (255, 255, 255) if i == 0 else ((100, 255, 100) if i == 1 else ((100, 200, 255) if i == 2 else (255, 100, 100)))
            d.text((x_pos, 8), f"{mname} (4x Zoom)", fill=color)
        out_path = BASE_DIR / filename
        strip.save(out_path)
        print(f"Saved {title} to {out_path}")

    # 2. Caitlyn Hero, Hat, Rifle (480, 200, 620, 340)
    create_zoom_strip((480, 200, 620, 340), "Caitlyn Zoom", "aa_caitlyn_zoom_4x.png")

    # 3. Dummy Head, Eyes, Floating Bar (DummyStatic ~ 780..900, 440..560)
    create_zoom_strip((780, 440, 900, 560), "Dummy Zoom", "aa_dummy_zoom_4x.png")

    # 4. Grid, Gold axis line, Green range ring (around 260..380, 300..420)
    create_zoom_strip((260, 300, 380, 420), "Grid & Ring Zoom", "aa_grid_rings_zoom_4x.png")

    # 5. HUD Status & Controls (10, 10, 210, 150)
    create_zoom_strip((10, 10, 210, 150), "HUD Detail Zoom", "aa_hud_zoom_4x.png")

    # 6. Measure differences against NO_FXAA on specific features:
    # A: Hero silhouette
    hero_rect = (480, 200, 620, 340)
    # B: Grid line / floor
    grid_rect = (260, 300, 380, 420)

    for name, r in [("Hero/Caitlyn", hero_rect), ("Grid/Rings", grid_rect)]:
        diff_full = ImageChops.difference(img_full.crop(r), img_nofx.crop(r))
        diff_m2 = ImageChops.difference(img_m2.crop(r), img_nofx.crop(r))
        diff_m4 = ImageChops.difference(img_m4.crop(r), img_nofx.crop(r))
        print(f"\n--- Region {name} differences vs NO_FXAA ---")
        print(f"  FULL vs NO_FXAA max diff:   {diff_full.getextrema()}")
        print(f"  MSAA2X vs NO_FXAA max diff: {diff_m2.getextrema()}")
        print(f"  MSAA4X vs NO_FXAA max diff: {diff_m4.getextrema()}")

if __name__ == "__main__":
    main()
