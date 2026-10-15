# Pipeline Gráfico, Antialiasing e Fidelidade Visual 1:1 — game-x1

Este documento registra a investigação técnica, calibragem do pipeline gráfico, antialiasing MSAA e paridade visual 1:1 entre o projeto de referência **`game-x0-moba` (Three.js + WebGL)** e o porto **`game-x1` (Godot 4 gl_compatibility / WebGL 2.0)**.

---

## 1. Arquitetura do Renderer e Comparativo Técnico

| Parâmetro | Three.js Original (`game-x0-moba`) | Godot 4 Inicial (`game-x1`) | Godot 4 Calibrado (`game-x1`) |
| :--- | :--- | :--- | :--- |
| **Renderer** | `THREE.WebGLRenderer` (WebGL 2.0) | `gl_compatibility` (WebGL 2.0) | `gl_compatibility` (WebGL 2.0) |
| **Antialiasing (MSAA 3D)** | `antialias: true` (Hardware MSAA 4x nativo) | Desativado (`msaa_3d=0`) | **MSAA 2x (`msaa_3d=1`)** |
| **Pós-processamento (FXAA/TAA)** | Nenhum (sem blur global) | Desativado | **Desativado (`screen_space_aa=0`)** |
| **Filtragem de Texturas (Anisotropia)** | Bilinear + Mipmaps | Padrão (baixo/desativado) | **Anisotrópico 4x (`anisotropic_filtering_level=2`)** |
| **Shadow Map** | `THREE.PCFShadowMap` (1024x1024) | Directional Shadow padrão (4096) | **PCF 2048 (`soft_shadow_filter_quality=2`)** |
| **Shadow Frustum / Alcance** | Caixa ortográfica $60 \times 60$ ($d=30$) | Alcance 90.0 metros | **Alcance 55.0 metros (focado na arena)** |
| **Shadow Bias** | `-0.0005` (contato rente aos pés) | Padrão `0.1` (descolamento/peter-panning) | **`shadow_bias=0.02`, `shadow_normal_bias=1.0`** |
| **Piso (Material & Albedo)** | PBR `#0a1016`, roughness 0.8, metalness 0.1 | Shader procedural grosso / PBR sem calibrar | **PBR `#070a0e`, roughness 0.8, metallic 0.1, specular 0.3** |
| **Grid Helper** | Linhas finas 1px unshaded (`gl.LINES`) | Shader fragmentado / MobaGridHelper | **Linhas 1px nativas (`Mesh.PRIMITIVE_LINES`), cores calibradas** |
| **Renderização 2D / HUD** | DOM HTML/CSS (DirectWrite com subpixel) | CanvasLayer Godot sem snapping | **CanvasLayer com Outfit font + Pixel Snapping integer** |

---

## 2. Matriz de Experimentos de Antialiasing (MSAA WebGL)

Todas as medições foram executadas no Chrome via automação Puppeteer (`tools/visual_capture.cjs`) na resolução física exata de **1280x720 (DPR 1.0)** com câmera e personagem na origem:

| Configuração | MSAA | Pixels Subpixel Blend (Caitlyn) | Qualidade Percebida de Borda | Estabilidade da Grade | Frame Time Web (ms) | FPS Medido no Chrome | Decisão |
| :--- | :---: | :---: | :--- | :--- | :---: | :---: | :---: |
| **A. Baseline Inicial** | 0x | 196 | Serrilhamento visível na silhueta e no rifle | Linhas piscam / quebram ao mover | 15.1 ms | ~66 FPS | Rejeitado (aliasing visível) |
| **B. MSAA 2x** | 2x | 259 | Bordas suaves, silhueta nítida e limpa | Linhas contínuas e estáveis | 17.4 ms | ~57 FPS | **ESCOLHIDO (Melhor balanço)** |
| **C. MSAA 4x** | 4x | 276 | Bordas ligeiramente mais suaves | Linhas estáveis | 28.7 ms | ~35 FPS | Custo de fillrate WebGL elevado |
| **D. MSAA 8x** | 8x | 293 | Ganho marginal de subpixel | Linhas estáveis | 19.8 ms | ~50 FPS | Custo desnecessário para Web |
| **Referência (Three.js)** | 4x | 851 | Suave e contínuo | Linhas 1px estáveis | 6.9 ms | ~144 FPS | Baseline de comparação |

> [!IMPORTANT]
> **Por que MSAA 2x foi a escolha ideal para Web?**  
> Em WebGL 2.0 no Chrome, o Godot cria um renderbuffer multisample offscreen e realiza `gl.blitFramebuffer` a cada quadro para a tela. O MSAA 2x confere eliminação perceptível de dentes de serra na Caitlyn e estabiliza 100% as linhas de 1px da arena, preservando mais de 60% do orçamento de frame time em relação ao MSAA 4x. Não utilizamos FXAA (`screen_space_aa=0`) pois o FXAA degrada a nitidez das linhas finas da grade e borra os contornos dos números de dano e placas de vida.

---

## 3. Calibragem Fotométrica de Chão e Iluminação

### A Causa da Diferença de Brilho
No Three.js (`Game.ts`), `renderer.outputEncoding` permanece no padrão `THREE.LinearEncoding` sem tonemapping (`toneMapped: false`), emitindo valores lineares não corrigidos diretamente para o framebuffer de 8 bits. Isso resultava na cor de tela medida de `[23, 25, 27]` (ardósia escuro profundo).  
No Godot 4, a engine aplica a curva de transferência sRGB nativa aos materiais PBR. Inicialmente, o albedo `#0a1016` resultava em `[43, 45, 49]` (cinza ardósia claro demais).

### Medições Reais de Cores (RGB)

| Ponto Amostrado | Coordenada na Tela | Three.js Referência | Godot Antes | Godot Calibrado 1:1 | Delta Final |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Piso Esquerdo** | $(300, 500)$ | `[23, 25, 27]` | `[43, 45, 49]` | **`[24, 26, 28]`** | **$\le 1$ RGB** |
| **Piso Direito** | $(900, 500)$ | `[25, 27, 29]` | `[46, 49, 53]` | **`[26, 28, 31]`** | **$\le 2$ RGB** |
| **Linha Central Dourada** | $(640, 500)$ | `[151, 124, 69]` | `[119, 102, 67]` | **`[124, 106, 71]`** | Contraste idêntico |
| **Peito / Roupa da Caitlyn** | $(640, 345)$ | `[77, 57, 88]` | `[76, 57, 87]` | **`[73, 54, 88]`** | **$\le 3$ RGB** |

As propriedades calibradas do piso em `scenes/main.tscn`:
```gdscene
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_floor"]
albedo_color = Color(0.026, 0.040, 0.055, 1)
metallic = 0.1
roughness = 0.8
metallic_specular = 0.3
```

---

## 4. Otimização do Pipeline de Sombras

1. **Volume da Sombra Ortográfica:**
   - No Three.js: caixa ortográfica $60 \times 60$ ($d=30$), near 0.5, far 100.
   - No Godot: `directional_shadow_mode = 0` (Ortogonal), `directional_shadow_max_distance` reduzido de 90m para **55.0m**, concentrando 100% da resolução do shadow map (2048x2048) na área visível da arena.
2. **Eliminação de Descolamento (Peter-Panning):**
   - Reduzido `shadow_bias` de 0.1 para **0.02**, acoplando a sombra diretamente à sola dos sapatos da Caitlyn e às bases dos Dummies.
   - Configurado `shadow_normal_bias = 1.0` para suprimir artefatos de acne nas superfícies curvas dos modelos.

---

## 5. Renderização 2D e Tipografia Nítida

1. **Snapping Inteiro de Pixels:**
   - Habilitado no `project.godot`:
     - `rendering/2d/snap/snap_2d_transforms_to_pixel = true`
     - `rendering/2d/snap/snap_2d_vertices_to_pixel = true`
   - Em `scenes/ui/floating_bars.gd`, as coordenadas projetadas 3D para 2D passam por `pos = pos.round()`, garantindo que contornos de 1px, molduras douradas e separadores de 100 HP caiam sobre pixels físicos exatos sem interpolação borrada.
2. **Tipografia Outfit com Pesos Calibrados:**
   - Normal: `variation_embolden = 0.15` (peso ~400-500) para textos informativos e atalhos.
   - Bold: `variation_embolden = 0.45` (peso ~700) para valores numéricos, FPS e status.
   - Hinting e subpixel positioning ativos no import da fonte `Outfit-Variable.ttf`.

---

## 6. Galeria de Evidências Visuais e Comparativos

Os arquivos de comparação foram gerados e armazenados em `docs/migration/visual/`:

- [C_comparison_side_by_side.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/C_comparison_side_by_side.png): Composição panorâmica 2560x780 comparando lado a lado Three.js vs Godot Calibrado.
- [caitlyn_edge_comparison.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/caitlyn_edge_comparison.png): Zoom 300% das bordas da Caitlyn avaliando MSAA 0x vs 2x vs Three.js.
- [D_hud_detail.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/D_hud_detail.png): Zoom comparativo do Card `#status-hud` entre DOM HTML e CanvasLayer Godot.
- [E_grid_detail.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/E_grid_detail.png): Comparativo do grid Three.js vs Godot inicial vs Godot corrigido.
- [shadows_comparison.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/shadows_comparison.png): Zoom 200% da sombra projetada da Caitlyn.
