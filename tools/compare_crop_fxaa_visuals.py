#!/usr/bin/env python3
"""
Inspect visual fidelity, seam artifacts, and smoothing differences between:
- full (production FXAA full screen)
- crop_fxaa_draw (real FXAA in 50% central ROI, full screen copy)
- crop_fxaa_copy (real FXAA in 50% central ROI, BackBufferCopy ROI+16px)
- no_fxaa (no post-processing)
"""

import sys
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont

BASE_DIR = Path("docs/migration/visual")

def main():
    img_full = Image.open(BASE_DIR / "crop_fxaa_full.png").convert("RGB")
    img_draw = Image.open(BASE_DIR / "crop_fxaa_crop_fxaa_draw.png").convert("RGB")
    img_copy = Image.open(BASE_DIR / "crop_fxaa_crop_fxaa_copy.png").convert("RGB")
    img_nofx = Image.open(BASE_DIR / "crop_fxaa_no_fxaa.png").convert("RGB")

    w, h = img_full.size
    print(f"Image dimensions: {w}x{h}")

    # Central ROI is 50% width, 50% height
    roi_x1 = int(round(w * 0.25)) # 320
    roi_y1 = int(round(h * 0.25)) # 180
    roi_x2 = roi_x1 + int(round(w * 0.5)) # 960
    roi_y2 = roi_y1 + int(round(h * 0.5)) # 540
    roi = (roi_x1, roi_y1, roi_x2, roi_y2)
    print(f"Crop ROI: {roi}")

    # 1. Compare outside ROI: crop_fxaa_draw vs no_fxaa
    diff_draw_nofx = ImageChops.difference(img_draw, img_nofx)
    # Mask inside ROI to check outside
    diff_outside = diff_draw_nofx.copy()
    draw_mask = ImageDraw.Draw(diff_outside)
    draw_mask.rectangle(roi, fill=(0, 0, 0))
    bbox_outside = diff_outside.getbbox()
    print(f"Difference outside ROI between crop_fxaa_draw and no_fxaa: {bbox_outside} (None means identical outside ROI)")

    # Same for crop_fxaa_copy vs no_fxaa outside ROI
    diff_copy_nofx = ImageChops.difference(img_copy, img_nofx)
    diff_copy_outside = diff_copy_nofx.copy()
    draw_mask2 = ImageDraw.Draw(diff_copy_outside)
    draw_mask2.rectangle(roi, fill=(0, 0, 0))
    bbox_copy_outside = diff_copy_outside.getbbox()
    print(f"Difference outside ROI between crop_fxaa_copy and no_fxaa: {bbox_copy_outside} (None means identical outside ROI)")

    # 2. Inside ROI: crop_fxaa_draw vs crop_fxaa_copy
    diff_draw_copy = ImageChops.difference(img_draw, img_copy)
    bbox_draw_copy = diff_draw_copy.getbbox()
    print(f"Difference between crop_fxaa_draw and crop_fxaa_copy: {bbox_draw_copy}")
    if bbox_draw_copy:
        stat = diff_draw_copy.crop(roi)
        # get max pixel difference
        extrema = stat.getextrema()
        print(f"Max channel difference inside ROI between draw and copy: {extrema}")

    # 3. Inside ROI: compare crop_fxaa_copy vs full
    diff_copy_full = ImageChops.difference(img_copy, img_full)
    roi_copy_full = diff_copy_full.crop(roi)
    print(f"Max channel difference inside ROI between crop_fxaa_copy and full: {roi_copy_full.getextrema()}")

    # 4. Inside ROI: compare crop_fxaa_copy vs no_fxaa
    roi_copy_nofx = diff_copy_nofx.crop(roi)
    print(f"Max channel difference inside ROI between crop_fxaa_copy and no_fxaa: {roi_copy_nofx.getextrema()}")

    # 5. Seam inspection: check pixels along the border of ROI
    # We inspect a 4-pixel strip across the seam (2 pixels inside, 2 pixels outside)
    border_strips = [
        ("Top border (y=179..181)", (roi_x1, roi_y1 - 2, roi_x2, roi_y1 + 2)),
        ("Bottom border (y=539..541)", (roi_x1, roi_y2 - 2, roi_x2, roi_y2 + 2)),
        ("Left border (x=319..321)", (roi_x1 - 2, roi_y1, roi_x1 + 2, roi_y2)),
        ("Right border (x=959..961)", (roi_x2 - 2, roi_y1, roi_x2 + 2, roi_y2)),
    ]
    for name, strip_rect in border_strips:
        strip_copy = img_copy.crop(strip_rect)
        strip_nofx = img_nofx.crop(strip_rect)
        strip_diff = ImageChops.difference(strip_copy, strip_nofx)
        print(f"Seam check {name}: max diff = {strip_diff.getextrema()}")

    # 6. Generate composite comparison image:
    # 2x2 grid showing Full, Crop Draw, Crop Copy, No FXAA with ROI highlighted and zooms
    canvas = Image.new("RGB", (1280 * 2, 720 * 2), (20, 20, 24))
    canvas.paste(img_full, (0, 0))
    canvas.paste(img_draw, (1280, 0))
    canvas.paste(img_copy, (0, 720))
    canvas.paste(img_nofx, (1280, 720))

    draw_c = ImageDraw.Draw(canvas)
    # Draw ROI boxes on all 4 quadrants
    draw_c.rectangle([roi_x1, roi_y1, roi_x2, roi_y2], outline=(0, 255, 255), width=2)
    draw_c.rectangle([1280 + roi_x1, roi_y1, 1280 + roi_x2, roi_y2], outline=(255, 255, 0), width=2)
    draw_c.rectangle([roi_x1, 720 + roi_y1, roi_x2, 720 + roi_y2], outline=(0, 255, 0), width=2)
    draw_c.rectangle([1280 + roi_x1, 720 + roi_y1, 1280 + roi_x2, 720 + roi_y2], outline=(255, 0, 0), width=2)

    # Add text banners
    draw_c.text((20, 20), "MODE: FULL (Production FXAA fullscreen)", fill=(255, 255, 255))
    draw_c.text((1300, 20), "MODE: CROP_FXAA_DRAW (Real FXAA in 50% ROI, Fullscreen copy)", fill=(255, 255, 255))
    draw_c.text((20, 740), "MODE: CROP_FXAA_COPY (Real FXAA in 50% ROI, BackBufferCopy ROI+16px)", fill=(255, 255, 255))
    draw_c.text((1300, 740), "MODE: NO_FXAA (Disabled FXAA, Raw 3D)", fill=(255, 255, 255))

    out_composite = BASE_DIR / "crop_fxaa_modes_visual_comparison.png"
    canvas.save(out_composite)
    print(f"Saved composite visual comparison to {out_composite}")

    # Also create a 4x zoom detail comparison of a high-contrast geometry inside ROI (e.g. Caitlyn rifle/hat/dummy)
    # Caitlyn is roughly at center (640, 420)
    zoom_rect = (580, 360, 700, 480) # 120x120
    zoom_full = img_full.crop(zoom_rect).resize((480, 480), Image.Resampling.NEAREST)
    zoom_copy = img_copy.crop(zoom_rect).resize((480, 480), Image.Resampling.NEAREST)
    zoom_nofx = img_nofx.crop(zoom_rect).resize((480, 480), Image.Resampling.NEAREST)

    zoom_canvas = Image.new("RGB", (480 * 3 + 40, 520), (15, 15, 18))
    zoom_canvas.paste(zoom_full, (10, 30))
    zoom_canvas.paste(zoom_copy, (500, 30))
    zoom_canvas.paste(zoom_nofx, (990, 30))

    draw_z = ImageDraw.Draw(zoom_canvas)
    draw_z.text((10, 8), "FULL (Production FXAA 4x Zoom)", fill=(255, 255, 255))
    draw_z.text((500, 8), "CROP_FXAA_COPY (Inside ROI 4x Zoom)", fill=(0, 255, 0))
    draw_z.text((990, 8), "NO_FXAA (Raw 3D Aliased 4x Zoom)", fill=(255, 100, 100))

    out_zoom = BASE_DIR / "crop_fxaa_detail_zoom_4x.png"
    zoom_canvas.save(out_zoom)
    print(f"Saved 4x zoom detail to {out_zoom}")

if __name__ == "__main__":
    main()
