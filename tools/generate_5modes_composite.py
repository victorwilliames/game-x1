import os
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = "docs/migration/visual"

def main():
    modes = [
        ("mode_5_full.png", "1. full (Producao)", "FXAA em tela cheia (100% resolucao)", (0, 220, 130)),
        ("mode_5_pass_only.png", "2. pass_only (Controle)", "Copia cheia, quad 100%, sem filtro AA", (255, 180, 40)),
        ("mode_5_crop_draw.png", "3. crop_draw (Diagnostico)", "Copia cheia, quad central 25% area", (255, 100, 100)),
        ("mode_5_crop_copy.png", "4. crop_copy (Diagnostico)", "BackBufferCopy regional 25% + quad 25%", (0, 200, 255)),
        ("mode_5_no_fxaa.png", "5. no_fxaa (Controle)", "Sem copia, sem quad (3D puro)", (180, 180, 180))
    ]

    images = []
    for fn, title, desc, col in modes:
        p = os.path.join(OUT_DIR, fn)
        img = Image.open(p).convert("RGB")
        images.append((img, title, desc, col))

    # We want a 5-panel composite showing the central area around Caitlyn and the dummy (zoom 2x)
    # Box: x: 500 to 780 (w=280), y: 250 to 470 (h=220)
    crop_box = (500, 250, 780, 470)
    w_crop, h_crop = 280, 220

    thumb_w, thumb_h = 280, 220
    canvas_w = 5 * thumb_w + 6 * 16
    canvas_h = thumb_h + 80
    comp = Image.new("RGB", (canvas_w, canvas_h), (18, 20, 24))
    draw = ImageDraw.Draw(comp)

    try:
        font_title = ImageFont.truetype("arial.ttf", 15)
        font_sub = ImageFont.truetype("arial.ttf", 11)
    except:
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    for idx, (img, title, desc, col) in enumerate(images):
        c = img.crop(crop_box)
        x = 16 + idx * (thumb_w + 16)
        y = 60
        comp.paste(c, (x, y))
        draw.rectangle([x - 1, y - 1, x + thumb_w, y + thumb_h], outline=col, width=2)
        draw.text((x + 4, 12), title, fill=col, font=font_title)
        draw.text((x + 4, 34), desc, fill=(180, 190, 200), font=font_sub)

    out_p = os.path.join(OUT_DIR, "all_5_modes_visual_comparison.png")
    comp.save(out_p)
    print(f"[Evidence] Saved 5-mode comparison to {out_p}")

if __name__ == "__main__":
    main()
