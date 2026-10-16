from PIL import Image, ImageDraw, ImageFont
import numpy as np
import os

VIS_DIR = "docs/migration/visual"

def load_img(name):
    return Image.open(os.path.join(VIS_DIR, name)).convert("RGB")

def make_header_panel(images, labels, title, scale=1):
    w, h = images[0].size
    sw, sh = w * scale, h * scale
    pad = 16
    top_h = 54
    total_w = len(images) * sw + (len(images) + 1) * pad
    total_h = top_h + sh + pad
    canvas = Image.new("RGB", (total_w, total_h), (8, 13, 20))
    draw = ImageDraw.Draw(canvas)
    try:
        font_title = ImageFont.truetype("assets/fonts/Outfit-Variable.ttf", 18)
        font_lbl = ImageFont.truetype("assets/fonts/Outfit-Variable.ttf", 14)
    except Exception:
        font_title = ImageFont.load_default()
        font_lbl = ImageFont.load_default()

    draw.text((pad, 8), title, fill=(255, 216, 138), font=font_title)
    for i, (im, lbl) in enumerate(zip(images, labels)):
        x = pad + i * (sw + pad)
        y = top_h
        resized = im.resize((sw, sh), Image.Resampling.NEAREST) if scale > 1 else im
        canvas.paste(resized, (x, y))
        draw.rectangle([x - 1, y - 1, x + sw, y + sh], outline=(194, 157, 83), width=1)
        draw.text((x + 4, 32), lbl, fill=(220, 230, 240), font=font_lbl)
    return canvas

def main():
    a_three = load_img("A_three_baseline.png")
    b0_before = load_img("B0_godot_before.png") if os.path.exists(os.path.join(VIS_DIR, "B0_godot_before.png")) else load_img("inspect_current_godot.png")
    b_after = load_img("B_godot_corrected.png")

    # 1. C_comparison_side_by_side.png (2560x780)
    c_comp = make_header_panel(
        [a_three, b_after],
        ["ESQUERDA: THREE.JS (REFERENCIA game-x0-moba)", "DIREITA: GODOT 4 (game-x1 CALIBRADO 1:1)"],
        "COMPARACAO LADO A LADO 1:1 — THREE.JS vs GODOT 4 (1280x720)",
        scale=1
    )
    c_comp.save(os.path.join(VIS_DIR, "C_comparison_side_by_side.png"))

    # 2. D_hud_detail.png (#status-hud crop: 10..335, 10..270)
    hud_box = (12, 12, 336, 272)
    d_hud = make_header_panel(
        [a_three.crop(hud_box), b0_before.crop(hud_box), b_after.crop(hud_box)],
        ["1. Three.js Original (#status-hud)", "2. Godot Antes (Desalinhado/Icones)", "3. Godot Agora (Outfit 500/700 + Monospace + Icones 1:1)"],
        "DETALHE COMPARATIVO DO HUD (#status-hud) — ESCALA 1:1 NATURAL",
        scale=1
    )
    d_hud.save(os.path.join(VIS_DIR, "D_hud_detail.png"))

    # 3. F_floating_bars_detail.png (Caitlyn + Dummies floating bars)
    bars_box = (550, 245, 815, 485)
    f_bars = make_header_panel(
        [a_three.crop(bars_box), b0_before.crop(bars_box), b_after.crop(bars_box)],
        ["1. Three.js Original", "2. Godot Antes (Texto colado/Capsula 1.5m)", "3. Godot Agora (Plate 1:1, Capsula 2.9m, Sombra e Textos)"],
        "PLACAS FLUTUANTES E DUMMIES (CAITLYN + DUMMIES) — ESCALA 200%",
        scale=2
    )
    f_bars.save(os.path.join(VIS_DIR, "F_floating_bars_detail.png"))

    # 4. shadows_comparison.png (REAL Caitlyn shadow on floor + foot contact!)
    # Caitlyn + shadow is at x=475..685, y=215..385
    shadow_box = (475, 215, 685, 385)
    s_comp = make_header_panel(
        [a_three.crop(shadow_box), b0_before.crop(shadow_box), b_after.crop(shadow_box)],
        ["1. Three.js (PCFSoftShadowMap)", "2. Godot Antes", "3. Godot Agora (PCF5 16-bit, Contato nos Pes e Rifle)"],
        "COMPARACAO REAL DA SOMBRA PROJETADA PELA CAITLYN E CONTATO COM OS PES (200%)",
        scale=2
    )
    s_comp.save(os.path.join(VIS_DIR, "shadows_comparison.png"))

    # 5. caitlyn_edge_comparison.png (Caitlyn silhouette, rifle edges, and plate)
    cait_box = (510, 210, 705, 380)
    e_cait = make_header_panel(
        [a_three.crop(cait_box), b_after.crop(cait_box)],
        ["1. Three.js (WebGL antialias: true)", "2. Godot 4 (MSAA 2x + Anisotropico 4x + Plate 1:1)"],
        "SILHUETA DA CAITLYN, BORDAS DO RIFLE E PLACA DE VIDA (ESCALA 200%)",
        scale=2
    )
    e_cait.save(os.path.join(VIS_DIR, "caitlyn_edge_comparison.png"))

    # 6. E_grid_detail.png (Floor, gold center line, secondary blue grid lines)
    grid_box = (720, 310, 980, 490)
    g_comp = make_header_panel(
        [a_three.crop(grid_box), b0_before.crop(grid_box), b_after.crop(grid_box)],
        ["1. Three.js (#0a1016 + #c29d53 + #162838)", "2. Godot Antes", "3. Godot Agora (Piso [25,27,30], Ouro #c29d53, Grid #162838)"],
        "DETALHE DO PISO E GRADE DA ARENA (EIXO DOURADO + CELULAS AZUIS) — ESCALA 200%",
        scale=2
    )
    g_comp.save(os.path.join(VIS_DIR, "E_grid_detail.png"))

    # 7. G_combat_damage_detail.png (Dynamic combat with floating damage numbers and active bars)
    if os.path.exists(os.path.join(VIS_DIR, "combat_three.png")) and os.path.exists(os.path.join(VIS_DIR, "combat_godot.png")):
        c_three = load_img("combat_three.png")
        c_godot = load_img("combat_godot.png")
        combat_box = (520, 220, 820, 480)
        combat_comp = make_header_panel(
            [c_three.crop(combat_box), c_godot.crop(combat_box)],
            ["1. Three.js em Combate (Dano Flutuante + Barras)", "2. Godot 4 em Combate (Outfit 900 + TextLine Cache)"],
            "COMBATE ATIVO: NUMEROS DE DANO FLUTUANTES E BARRAS EM TEMPO REAL (ESCALA 200%)",
            scale=2
        )
        combat_comp.save(os.path.join(VIS_DIR, "G_combat_damage_detail.png"))

    print("All visual evidence composites generated successfully!")

if __name__ == "__main__":
    main()
