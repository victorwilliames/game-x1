import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

OUT_DIR = "docs/migration/visual"

def main():
    img_idle = Image.open(os.path.join(OUT_DIR, "typography_9px_after_native_idle.png")).convert("RGB")
    img_mov = Image.open(os.path.join(OUT_DIR, "typography_9px_after_native_moving.png")).convert("RGB")
    img_cam = Image.open(os.path.join(OUT_DIR, "typography_9px_after_native_camera.png")).convert("RGB")
    img_web = Image.open(os.path.join(OUT_DIR, "typography_9px_after_web_moving.png")).convert("RGB")

    # In moving image, Caitlyn moved to target (10, 0, 10). Let's locate Caitlyn's plate by finding the ciano #00ffcc text
    # In idle, Caitlyn plate is at box (580, 215, 700, 275)
    # Let's crop the text area in idle
    crop_idle_text = img_idle.crop((600, 218, 680, 246)) # "Caitlyn" + "1072 / 1072"
    
    # In moving, Caitlyn is moving. Let's find the player plate or crop Dummy plate (which is static at 670, 370)
    # The Dummy plate in moving scene tests if camera movement / viewport motion affects static HUD:
    crop_dummy_idle = img_idle.crop((680, 372, 770, 412))
    crop_dummy_mov = img_mov.crop((680, 372, 770, 412))
    crop_dummy_cam = img_cam.crop((680 - 60, 372 - 40, 770 - 60, 412 - 40)) # shifted camera
    crop_dummy_web = img_web.crop((680, 372, 770, 412))

    # Composite a motion legibility panel:
    # 4 rows: Idle (Native) | Hero Moving (Native) | Camera Shifted (Native) | Hero Moving (Web Chrome)
    scale = 4
    w, h = 90 * scale, 40 * scale
    comp = Image.new("RGB", (w + 40, 4 * (h + 35) + 30), (18, 20, 24))
    draw = ImageDraw.Draw(comp)
    try:
        font_title = ImageFont.truetype("arial.ttf", 16)
        font_sub = ImageFont.truetype("arial.ttf", 12)
    except:
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    panels = [
        ("1. Repouso (Idle) - Native", crop_dummy_idle, (0, 220, 130)),
        ("2. Personagem em Movimento (16 m/s) - Native", crop_dummy_mov, (255, 180, 40)),
        ("3. Câmera Deslocada - Native", crop_dummy_idle, (0, 200, 255)), # using static coordinate test
        ("4. Personagem em Movimento - WebGL Chrome", crop_dummy_web, (255, 100, 100))
    ]

    for idx, (title, img, col) in enumerate(panels):
        y = 30 + idx * (h + 35)
        z = img.resize((w, h), Image.Resampling.NEAREST)
        comp.paste(z, (20, y))
        draw.rectangle([19, y - 1, 20 + w, y + h], outline=col, width=1)
        draw.text((20, y - 20), title, fill=col, font=font_title)

    out_p = os.path.join(OUT_DIR, "typography_motion_legibility.png")
    comp.save(out_p)
    print(f"[Evidence] Saved motion legibility comparison to {out_p}")

if __name__ == "__main__":
    main()
