import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

OUT_DIR = "docs/migration/visual"

def main():
    path_before = os.path.join(OUT_DIR, "typography_9px_before.png")
    path_after_nat = os.path.join(OUT_DIR, "typography_9px_after_native_idle.png")
    path_after_mov = os.path.join(OUT_DIR, "typography_9px_after_native_moving.png")
    path_after_web = os.path.join(OUT_DIR, "typography_9px_after_web_idle.png")

    img_before = Image.open(path_before).convert("RGB")
    img_after_nat = Image.open(path_after_nat).convert("RGB")
    img_after_mov = Image.open(path_after_mov).convert("RGB")
    img_after_web = Image.open(path_after_web).convert("RGB")

    # Crop Caitlyn plate box: (580, 215, 700, 275) -> 120x60
    box_caitlyn = (580, 215, 700, 275)
    # Crop Dummy plate box: (670, 370, 780, 420) -> 110x50
    box_dummy = (670, 370, 780, 420)
    # Crop Status HUD top: (10, 10, 220, 90) -> 210x80
    box_hud = (10, 10, 220, 90)

    c_caitlyn_bef = img_before.crop(box_caitlyn)
    c_caitlyn_aft = img_after_nat.crop(box_caitlyn)
    c_caitlyn_web = img_after_web.crop(box_caitlyn)

    c_dummy_bef = img_before.crop(box_dummy)
    c_dummy_aft = img_after_nat.crop(box_dummy)
    c_dummy_web = img_after_web.crop(box_dummy)

    c_hud_bef = img_before.crop(box_hud)
    c_hud_aft = img_after_nat.crop(box_hud)

    # 4x zoom for detailed inspection
    scale = 4
    w_c, h_c = 120 * scale, 60 * scale
    w_d, h_d = 110 * scale, 50 * scale

    z_c_bef = c_caitlyn_bef.resize((w_c, h_c), Image.Resampling.NEAREST)
    z_c_aft = c_caitlyn_aft.resize((w_c, h_c), Image.Resampling.NEAREST)
    z_c_web = c_caitlyn_web.resize((w_c, h_c), Image.Resampling.NEAREST)

    z_d_bef = c_dummy_bef.resize((w_d, h_d), Image.Resampling.NEAREST)
    z_d_aft = c_dummy_aft.resize((w_d, h_d), Image.Resampling.NEAREST)
    z_d_web = c_dummy_web.resize((w_d, h_d), Image.Resampling.NEAREST)

    # Create composite comparison image:
    # 3 columns: Before (Commit 3a49ee7) | After Native (Commit 304d72d) | After Web (Commit 304d72d)
    col_w = max(w_c, w_d) + 30
    canvas_w = 3 * col_w + 40
    canvas_h = h_c + h_d + 180
    comp = Image.new("RGB", (canvas_w, canvas_h), (18, 20, 24))
    draw = ImageDraw.Draw(comp)

    try:
        font_title = ImageFont.truetype("arial.ttf", 18)
        font_sub = ImageFont.truetype("arial.ttf", 13)
    except:
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    draw.text((20, 14), "Validação da Fonte Outfit (9px) - Comparativo Antes vs Depois (Zoom 4x)", fill=(0, 220, 130), font=font_title)
    draw.text((20, 38), "Ajuste no moba_fonts.gd: hinting=LIGHT, subpixel_positioning=AUTO, oversampling=2.0", fill=(180, 190, 200), font=font_sub)

    cols = [
        ("1. ANTES (Base 3a49ee7)", "Sem oversampling / defaults", z_c_bef, z_d_bef, (255, 100, 100)),
        ("2. DEPOIS (Nativo 304d72d)", "Oversampling 2.0x / Hinting LIGHT", z_c_aft, z_d_aft, (0, 220, 130)),
        ("3. DEPOIS (Web Chrome)", "WebGL2 / Oversampling 2.0x", z_c_web, z_d_web, (0, 200, 255))
    ]

    for idx, (title, sub, img_c, img_d, col) in enumerate(cols):
        x = 20 + idx * col_w
        y1 = 80
        comp.paste(img_c, (x, y1))
        draw.rectangle([x - 1, y1 - 1, x + w_c, y1 + h_c], outline=col, width=2)
        draw.text((x + 4, y1 - 22), title, fill=col, font=font_title)

        y2 = y1 + h_c + 30
        comp.paste(img_d, (x, y2))
        draw.rectangle([x - 1, y2 - 1, x + w_d, y2 + h_d], outline=col, width=2)
        draw.text((x + 4, y2 - 20), "Dummy (9px)", fill=(180, 190, 200), font=font_sub)

    out_p = os.path.join(OUT_DIR, "typography_outfit_before_after.png")
    comp.save(out_p)
    print(f"[Evidence] Saved comparison to {out_p}")

    # Pixel difference metrics
    arr_c_bef = np.array(c_caitlyn_bef, dtype=float)
    arr_c_aft = np.array(c_caitlyn_aft, dtype=float)
    diff_c = np.abs(arr_c_aft - arr_c_bef)
    print(f"\n--- Pixel Difference Metrics (Caitlyn 120x60 plate) ---")
    print(f"  • Max pixel delta:  {diff_c.max():.2f}")
    print(f"  • Mean pixel delta: {diff_c.mean():.4f}")
    print(f"  • Non-zero pixels modified: {np.count_nonzero(diff_c)} / {diff_c.size} ({np.count_nonzero(diff_c)/diff_c.size*100:.2f}%)")

if __name__ == "__main__":
    main()
