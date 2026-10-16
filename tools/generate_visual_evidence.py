from PIL import Image, ImageDraw, ImageFont
import numpy as np
import os

VIS_DIR = "docs/migration/visual"

def load_img(name):
    p = os.path.join(VIS_DIR, name)
    if not os.path.exists(p):
        return None
    return Image.open(p).convert("RGB")

def make_header_panel(images, labels, title, scale=1):
    valid_pairs = [(im, lbl) for im, lbl in zip(images, labels) if im is not None]
    if not valid_pairs:
        return None
    ims, lbls = zip(*valid_pairs)
    w, h = ims[0].size
    sw, sh = w * scale, h * scale
    pad = 16
    top_h = 58
    total_w = len(ims) * sw + (len(ims) + 1) * pad
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
    for i, (im, lbl) in enumerate(zip(ims, lbls)):
        x = pad + i * (sw + pad)
        y = top_h
        resized = im.resize((sw, sh), Image.Resampling.NEAREST) if scale > 1 else im
        canvas.paste(resized, (x, y))
        draw.rectangle([x - 1, y - 1, x + sw, y + sh], outline=(194, 157, 83), width=1)
        draw.text((x + 4, 34), lbl, fill=(220, 230, 240), font=font_lbl)
    return canvas

def main():
    a_three = load_img("A_three_baseline.png")
    b_fxaa = load_img("B_godot_fxaa3d.png")
    b_msaa0x = load_img("B_godot_msaa0x.png")
    b_msaa2x = load_img("B_godot_msaa2x.png")
    b_corrected = load_img("B_godot_corrected.png")
    b_active = b_fxaa if b_fxaa is not None else b_corrected

    if a_three is None or b_active is None:
        print("Waiting for baseline images to be captured...")
        return

    # 1. C_comparison_side_by_side.png (Full View 1280x720 side-by-side)
    c_comp = make_header_panel(
        [a_three, b_active],
        ["ESQUERDA: THREE.JS (REFERENCIA ORIGINAL game-x0-moba)", "DIREITA: GODOT 4 (game-x1 FXAA-3D + FITAS DOURADAS UV FIX)"],
        "COMPARACAO LADO A LADO 1:1 — THREE.JS vs GODOT 4 (1280x720)",
        scale=1
    )
    if c_comp:
        c_comp.save(os.path.join(VIS_DIR, "C_comparison_side_by_side.png"))

    # 2. caitlyn_edge_comparison_4x.png (ZOOM 400% on Caitlyn Silhouette & Rifle Edge)
    # Caitlyn silhouette center in 1280x720: (580, 270, 680, 370)
    cait_box = (580, 270, 680, 370)
    cait_images = [a_three.crop(cait_box)]
    cait_labels = ["1. Three.js (WebGL Native AA)"]
    if b_msaa0x:
        cait_images.append(b_msaa0x.crop(cait_box))
        cait_labels.append("2. Godot 4 (AA OFF - Serrilhado)")
    if b_msaa2x:
        cait_images.append(b_msaa2x.crop(cait_box))
        cait_labels.append("3. Godot 4 (MSAA 2x - Custo +7.8ms)")
    if b_fxaa:
        cait_images.append(b_fxaa.crop(cait_box))
        cait_labels.append("4. Godot 4 (FXAA-3D - Proposta <1ms)")

    cait_4x = make_header_panel(
        cait_images,
        cait_labels,
        "ZOOM 400% (4X) SILHUETA DA CAITLYN, CABELO E CANO DO RIFLE — COMPARATIVO DE ANTIALIASING",
        scale=4
    )
    if cait_4x:
        cait_4x.save(os.path.join(VIS_DIR, "caitlyn_edge_comparison_4x.png"))

    # Backward compatible 2x zoom
    e_cait = make_header_panel(
        [a_three.crop(cait_box), b_active.crop(cait_box)],
        ["1. Three.js (WebGL antialias: true)", "2. Godot 4 (FXAA-3D Post-Process Shader)"],
        "SILHUETA DA CAITLYN E BORDAS DO RIFLE (ESCALA 200%)",
        scale=2
    )
    if e_cait:
        e_cait.save(os.path.join(VIS_DIR, "caitlyn_edge_comparison.png"))

    # 3. gold_ribbons_detail_4x.png (ZOOM 400% on Gold Ribbon X & Z with UV feathering fix)
    # Floor ribbons cross at arena origin (640, 360): (590, 310, 690, 410)
    ribbon_box = (590, 310, 690, 410)
    ribbon_images = [a_three.crop(ribbon_box), b_active.crop(ribbon_box)]
    ribbon_labels = [
        "1. Three.js (Eixo Ouro #c29d53 Original)",
        "2. Godot 4 (Fita Z UV Corrigido: Suavizacao Transversal 1:1)"
    ]
    ribbon_4x = make_header_panel(
        ribbon_images,
        ribbon_labels,
        "ZOOM 400% (4X) FITAS DOURADAS CENTRAIS — CORRECAO DE MAPEAMENTO UV TRANSVERSAL (ETAPA 1)",
        scale=4
    )
    if ribbon_4x:
        ribbon_4x.save(os.path.join(VIS_DIR, "gold_ribbons_detail_4x.png"))

    # 4. dummies_ring_detail_4x.png (ZOOM 400% on DummyStatic and Red Tolerance Ring)
    # DummyStatic is at (7, 0, 7) -> screen pos around (720, 380, 820, 480)
    dummy_box = (720, 380, 820, 480)
    dummy_4x = make_header_panel(
        [a_three.crop(dummy_box), b_active.crop(dummy_box)],
        ["1. Three.js (Dummy + Anel Tolerancia)", "2. Godot 4 (RingMeshBuilder Shader Suave + Dummy 1:1)"],
        "ZOOM 400% (4X) DUMMY VERMELHO E ANEL DE TOLERANCIA DE COMBATE",
        scale=4
    )
    if dummy_4x:
        dummy_4x.save(os.path.join(VIS_DIR, "dummies_ring_detail_4x.png"))

    # 5. typography_detail_4x.png (ZOOM 400% on Status HUD & Floating Health Bar Text)
    # Status HUD Caitlyn name/HP box: (16, 16, 216, 80)
    typo_box = (16, 16, 216, 80)
    typo_4x = make_header_panel(
        [a_three.crop(typo_box), b_active.crop(typo_box)],
        ["1. Three.js (Outfit Regular/Bold CSS)", "2. Godot 4 (Outfit 500/700 + Sombra 1px + Intacta fora do FXAA)"],
        "ZOOM 400% (4X) TIPOGRAFIA OUTFIT E LEGUIBILIDADE — PRESERVADA FORA DO POS-PROCESSAMENTO",
        scale=4
    )
    if typo_4x:
        typo_4x.save(os.path.join(VIS_DIR, "typography_detail_4x.png"))

    # 6. D_hud_detail.png (Full HUD box 1:1)
    hud_box = (12, 12, 336, 272)
    d_hud = make_header_panel(
        [a_three.crop(hud_box), b_active.crop(hud_box)],
        ["1. Three.js Original (#status-hud)", "2. Godot 4 (Outfit 500/700 + Monospace + Sombra 1px)"],
        "DETALHE COMPARATIVO DO HUD (#status-hud) — ESCALA 1:1 NATURAL",
        scale=1
    )
    if d_hud:
        d_hud.save(os.path.join(VIS_DIR, "D_hud_detail.png"))

    # 7. F_floating_bars_detail.png (Caitlyn & Dummy floating bars 200%)
    bars_box = (550, 245, 815, 485)
    f_bars = make_header_panel(
        [a_three.crop(bars_box), b_active.crop(bars_box)],
        ["1. Three.js Original", "2. Godot 4 (Placas Flutuantes 1:1, Altura 2.9m, Textos Nítidos)"],
        "PLACAS FLUTUANTES (CAITLYN + DUMMIES) — ESCALA 200%",
        scale=2
    )
    if f_bars:
        f_bars.save(os.path.join(VIS_DIR, "F_floating_bars_detail.png"))

    # 8. shadows_comparison.png (Real Caitlyn shadow on floor 200%)
    shadow_box = (475, 215, 685, 385)
    s_comp = make_header_panel(
        [a_three.crop(shadow_box), b_active.crop(shadow_box)],
        ["1. Three.js (PCFSoftShadowMap)", "2. Godot 4 (PCF5 16-bit, Sombra Direcional 1:1)"],
        "COMPARACAO DA SOMBRA PROJETADA PELA CAITLYN E CONTATO COM O PISO (ESCALA 200%)",
        scale=2
    )
    if s_comp:
        s_comp.save(os.path.join(VIS_DIR, "shadows_comparison.png"))

    # 9. G_combat_damage_detail.png (Floating damage in action)
    if os.path.exists(os.path.join(VIS_DIR, "combat_three.png")) and os.path.exists(os.path.join(VIS_DIR, "combat_godot.png")):
        c_three = load_img("combat_three.png")
        c_godot = load_img("combat_godot.png")
        combat_box = (520, 220, 820, 480)
        combat_comp = make_header_panel(
            [c_three.crop(combat_box), c_godot.crop(combat_box)],
            ["1. Three.js em Combate (Dano Flutuante)", "2. Godot 4 em Combate (Outfit 900 Amarelo + FXAA)"],
            "COMBATE ATIVO: NUMEROS DE DANO FLUTUANTES E BARRAS EM TEMPO REAL (ESCALA 200%)",
            scale=2
        )
        if combat_comp:
            combat_comp.save(os.path.join(VIS_DIR, "G_combat_damage_detail.png"))

    print("All enhanced visual evidence composites generated successfully!")

if __name__ == "__main__":
    main()
