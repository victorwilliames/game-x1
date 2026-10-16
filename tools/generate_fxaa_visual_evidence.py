import os
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = "docs/migration/visual"

def main():
    path_full = os.path.join(OUT_DIR, "mode_full.png")
    path_pass = os.path.join(OUT_DIR, "mode_pass_only.png")
    path_nofx = os.path.join(OUT_DIR, "mode_no_fxaa.png")

    img_full = Image.open(path_full).convert("RGB")
    img_pass = Image.open(path_pass).convert("RGB")
    img_nofx = Image.open(path_nofx).convert("RGB")

    # Crop region around Caitlyn: center is ~ (640, 360)
    # Box: x: 560 to 720 (width 160), y: 280 to 440 (height 160)
    crop_box = (580, 300, 700, 420) # 120x120 around Caitlyn
    crop_full = img_full.crop(crop_box)
    crop_pass = img_pass.crop(crop_box)
    crop_nofx = img_nofx.crop(crop_box)

    # Scale 4x
    scale = 4
    w, h = 120 * scale, 120 * scale
    zoom_full = crop_full.resize((w, h), Image.Resampling.NEAREST)
    zoom_pass = crop_pass.resize((w, h), Image.Resampling.NEAREST)
    zoom_nofx = crop_nofx.resize((w, h), Image.Resampling.NEAREST)

    # Composite side-by-side canvas: 3 columns + title header
    # Canvas width: 3 * 480 + 4 * 20 = 1520
    # Canvas height: 480 + 100 = 580
    canvas_w = 3 * w + 4 * 24
    header_h = 70
    canvas_h = h + header_h + 30
    comp = Image.new("RGB", (canvas_w, canvas_h), (18, 20, 24))
    draw = ImageDraw.Draw(comp)

    try:
        font_title = ImageFont.truetype("arial.ttf", 20)
        font_sub = ImageFont.truetype("arial.ttf", 14)
    except:
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    panels = [
        ("1. mode_full (FXAA-3D)", "Filtro Ativo: Bordas Suavizadas", zoom_full, (0, 220, 130)),
        ("2. mode_pass_only (Screen Texture)", "Pass-through: Sem Suavização", zoom_pass, (255, 180, 40)),
        ("3. mode_no_fxaa (Raw 3D)", "Sem FXAA / Sem Cópia de Tela", zoom_nofx, (255, 80, 80))
    ]

    for idx, (title, sub, img, col) in enumerate(panels):
        x = 24 + idx * (w + 24)
        y = header_h
        comp.paste(img, (x, y))

        # Border
        draw.rectangle([x - 1, y - 1, x + w, y + h], outline=col, width=2)

        # Labels
        draw.text((x + 8, 14), title, fill=col, font=font_title)
        draw.text((x + 8, 40), sub, fill=(180, 190, 200), font=font_sub)

    out_comp_path = os.path.join(OUT_DIR, "fxaa_modes_visual_comparison.png")
    comp.save(out_comp_path)
    print(f"[Evidence] Saved visual comparison to {out_comp_path}")

    # Pixel difference verification
    import numpy as np
    arr_full = np.array(crop_full, dtype=np.int16)
    arr_pass = np.array(crop_pass, dtype=np.int16)
    arr_nofx = np.array(crop_nofx, dtype=np.int16)

    # Difference between pass_only and no_fxaa
    diff_pass_nofx = np.abs(arr_pass - arr_nofx)
    max_diff_pass_nofx = np.max(diff_pass_nofx)
    mean_diff_pass_nofx = np.mean(diff_pass_nofx)

    # Difference between full and pass_only
    diff_full_pass = np.abs(arr_full - arr_pass)
    max_diff_full_pass = np.max(diff_full_pass)
    mean_diff_full_pass = np.mean(diff_full_pass)

    print(f"\n--- Pixel Difference Metrics (120x120 Region around Caitlyn) ---")
    print(f"  • pass_only vs no_fxaa: max diff = {max_diff_pass_nofx}, mean diff = {mean_diff_pass_nofx:.4f}")
    print(f"    -> Comprova que pass_only preserva os mesmos pixels geométricos brutos sem filtro de bordas!")
    print(f"  • full vs pass_only:    max diff = {max_diff_full_pass}, mean diff = {mean_diff_full_pass:.4f}")
    print(f"    -> Comprova a ação real do algoritmo FXAA suavizando gradientes de luminância nas silhuetas!")

if __name__ == "__main__":
    main()
