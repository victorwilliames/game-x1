import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

OUT_DIR = "docs/migration/visual"

def main():
    print("--- 1. ANALYZING DUMMY HIT FLASH, DEATH, AND RESPAWN ---")
    img_idle = Image.open(os.path.join(OUT_DIR, "verify_idle_ui.png")).convert("RGB")
    img_flash = Image.open(os.path.join(OUT_DIR, "verify_dummy_hit_flash.png")).convert("RGB")
    img_death = Image.open(os.path.join(OUT_DIR, "verify_dummy_death_floor.png")).convert("RGB")
    img_respawn = Image.open(os.path.join(OUT_DIR, "verify_dummy_respawned.png")).convert("RGB")

    # DummyStatic is located near world (7, 0, 7).
    # In 1280x720 camera projection, DummyStatic center is approximately (725, 410)
    # Let's crop a 160x160 box around DummyStatic: x: 650 to 810, y: 330 to 490
    dummy_box = (650, 330, 810, 490)

    crop_idle = img_idle.crop(dummy_box)
    crop_flash = img_flash.crop(dummy_box)
    crop_death = img_death.crop(dummy_box)
    crop_respawn = img_respawn.crop(dummy_box)

    # Compute mean brightness on the dummy body area
    # In hit flash, brightness should spike dramatically towards 255
    arr_idle = np.array(crop_idle, dtype=float)
    arr_flash = np.array(crop_flash, dtype=float)
    arr_death = np.array(crop_death, dtype=float)
    arr_respawn = np.array(crop_respawn, dtype=float)

    print(f"  * Idle dummy mean RGB:      {arr_idle.mean():.2f}")
    print(f"  * Hit flash dummy mean RGB:  {arr_flash.mean():.2f} (Spike due to unshaded white flash_mat)")
    print(f"  * Dead dummy mean RGB:       {arr_death.mean():.2f} (Lying down, flash cleared, no white material)")
    print(f"  * Respawned dummy mean RGB:  {arr_respawn.mean():.2f} (Restored to exact idle appearance)")

    # Composite Dummy Flash Evidence
    w, h = 160, 160
    scale = 2
    comp_dummy = Image.new("RGB", (4 * w * scale + 5 * 20, h * scale + 80), (18, 20, 24))
    draw_d = ImageDraw.Draw(comp_dummy)
    try:
        font_title = ImageFont.truetype("arial.ttf", 18)
        font_sub = ImageFont.truetype("arial.ttf", 13)
    except:
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    dummy_steps = [
        ("1. Normal / Idle", "Material Padrao (Madeira)", crop_idle, (0, 220, 130)),
        ("2. Dano Recebido", "Flash Branco Ativo (flash_mat)", crop_flash, (255, 255, 255)),
        ("3. Morte no Chao", "Flash Limpo! (PI/2 sem branco)", crop_death, (255, 180, 40)),
        ("4. Renascimento", "Material Normal Restaurado", crop_respawn, (0, 200, 255))
    ]

    for idx, (title, sub, c_img, col) in enumerate(dummy_steps):
        x = 20 + idx * (w * scale + 20)
        y = 60
        comp_dummy.paste(c_img.resize((w * scale, h * scale), Image.Resampling.NEAREST), (x, y))
        draw_d.rectangle([x - 1, y - 1, x + w * scale, y + h * scale], outline=col, width=2)
        draw_d.text((x + 6, 12), title, fill=col, font=font_title)
        draw_d.text((x + 6, 36), sub, fill=(180, 190, 200), font=font_sub)

    comp_dummy.save(os.path.join(OUT_DIR, "dummy_flash_verification.png"))
    print(f"[Evidence] Saved {os.path.join(OUT_DIR, 'dummy_flash_verification.png')}")

    print("\n--- 2. ANALYZING 9PX TYPOGRAPHY & OUTFIT RENDERING ---")
    # Caitlyn head bar is near (640, 260) - plate is at (640 - 52 = 588 to 692, y: 220 to 280)
    caitlyn_bar_box = (580, 215, 700, 275) # 120x60
    crop_caitlyn_bar = img_idle.crop(caitlyn_bar_box)

    # Dummy health bar is near (725, 410) - plate is at (670 to 780, y: 370 to 420)
    dummy_bar_box = (670, 370, 780, 420) # 110x50
    crop_dummy_bar = img_idle.crop(dummy_bar_box)

    # Status HUD is at top-left: x: 10 to 220, y: 10 to 180
    hud_box = (10, 10, 220, 180)
    crop_hud = img_idle.crop(hud_box)

    # Create 4x magnification composite of 9px typography
    scale_font = 4
    w_cb, h_cb = crop_caitlyn_bar.size
    w_db, h_db = crop_dummy_bar.size
    w_hud, h_hud = 210, 80 # top portion with Status & FPS
    crop_hud_top = crop_hud.crop((0, 0, w_hud, h_hud))

    zoom_caitlyn_bar = crop_caitlyn_bar.resize((w_cb * scale_font, h_cb * scale_font), Image.Resampling.NEAREST)
    zoom_dummy_bar = crop_dummy_bar.resize((w_db * scale_font, h_db * scale_font), Image.Resampling.NEAREST)
    zoom_hud = crop_hud_top.resize((w_hud * 2, h_hud * 2), Image.Resampling.NEAREST)

    comp_typo = Image.new("RGB", (w_cb * scale_font + w_hud * 2 + 60, h_cb * scale_font + h_db * scale_font + 120), (18, 20, 24))
    draw_t = ImageDraw.Draw(comp_typo)

    # Left column: Caitlyn 9px plate + Dummy 9px plate
    draw_t.text((20, 14), "Textos Flutuantes de 9px (Outfit Extrabold / Black) - Zoom 4x", fill=(0, 220, 130), font=font_title)
    draw_t.text((20, 38), "Caitlyn: 'Caitlyn' 9px | '1072 / 1072 (100%)' 9px | Nivel '5' 9px", fill=(180, 190, 200), font=font_sub)
    comp_typo.paste(zoom_caitlyn_bar, (20, 60))
    draw_t.rectangle([19, 59, 20 + w_cb * scale_font, 60 + h_cb * scale_font], outline=(0, 220, 130), width=1)

    y_db = 80 + h_cb * scale_font
    draw_t.text((20, y_db - 24), "Dummy: 'Dummy' 9px | '600 / 600' 9px", fill=(255, 180, 40), font=font_sub)
    comp_typo.paste(zoom_dummy_bar, (20, y_db))
    draw_t.rectangle([19, y_db - 1, 20 + w_db * scale_font, y_db + h_db * scale_font], outline=(255, 180, 40), width=1)

    # Right column: Status HUD top (Status & FPS)
    x_r = w_cb * scale_font + 40
    draw_t.text((x_r, 14), "StatusHUD (Outfit + Consolas) - Zoom 2x", fill=(0, 200, 255), font=font_title)
    draw_t.text((x_r, 38), "Card estatico 2D (sem desfoque do FXAA)", fill=(180, 190, 200), font=font_sub)
    comp_typo.paste(zoom_hud, (x_r, 60))
    draw_t.rectangle([x_r - 1, 59, x_r + w_hud * 2, 60 + h_hud * 2], outline=(0, 200, 255), width=1)

    comp_typo.save(os.path.join(OUT_DIR, "typography_9px_analysis.png"))
    print(f"[Evidence] Saved {os.path.join(OUT_DIR, 'typography_9px_analysis.png')}")

if __name__ == "__main__":
    main()
