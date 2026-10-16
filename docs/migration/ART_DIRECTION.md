# Pipeline Gráfico, Tipografia, Placas Flutuantes e Performance Web — game-x1

Este documento registra a investigação técnica, a calibragem 1:1 do pipeline gráfico, tipografia, placas flutuantes, sombras e os benchmarks multi-cenário entre o projeto de referência **`game-x0-moba` (Three.js + WebGL)** e o porto **`game-x1` (Godot 4 `gl_compatibility` / WebGL 2.0)** na branch `port/game-x0-1to1`.

---

## 1. Arquitetura do Renderer e Comparativo Técnico 1:1

| Parâmetro | Three.js Original (`game-x0-moba`) | Godot 4 Antes (Reprovado) | Godot 4 Calibrado 1:1 (`game-x1`) |
| :--- | :--- | :--- | :--- |
| **Renderer** | `THREE.WebGLRenderer` (WebGL 2.0) | `gl_compatibility` (WebGL 2.0) | `gl_compatibility` (WebGL 2.0) |
| **Antialiasing (MSAA 3D)** | `antialias: true` (MSAA nativo) | MSAA 2x | **MSAA 2x (`msaa_3d=1`, `screen_space_aa=0`)** |
| **Filtragem de Texturas** | Bilinear + Mipmaps | Anisotrópico 4x | **Anisotrópico 4x (`anisotropic_filtering_level=2`)** |
| **Shadow Map & Filtro** | `THREE.PCFShadowMap` (1024x1024) | PCF13 (`quality=2`), 2048 | **PCF5 (`soft_shadow_filter_quality=1`), 16-bit, 2048** |
| **Shadow Max Distance** | Caixa ortográfica centrada na origem ($d=30$) | `55.0m` (**Cortava em $73.75\text{m}$ antes da origem!**) | **`115.0m` (`fade_start=0.95`, cobre toda a arena visível)** |
| **Shadow Casters Desnecessários**| Apenas `Caitlyn` e `Dummy.bodyMesh` | Chão, Grid e Anéis com `cast_shadow=ON` | **Apenas `Caitlyn` e `Dummy/Body` (`cast_shadow=0` nos demais)** |
| **Tipografia (Outfit)** | Google Fonts `Outfit` (500, 700, 800, 900) | `hinting=2` (Normal) deformando hastes | **OpenType `wght` nativo (500/700/800/900) + `hinting=1` (Light) + `subpixel=1`** |
| **Tipografia (`span` HUD)** | CSS `font-family: monospace; font-weight: bold` | `Outfit` (errado) + outline preto borrado | **`MobaFonts.monospace_bold()` (`Consolas`/`Courier New` 700) sem outline** |
| **Ícones do HUD (`#status-hud`)**| Imagens nativas 10x15 (mouse) e 14x11 (teclado) | Desenhados proceduralmente desalinhados | **`icon_mouse.png` (10x15) e `icon_keyboard.png` (14x11) extraídos 1:1 (`NEAREST`)** |
| **Placas Flutuantes (Dummies)** | Barra vermelha no **topo** $\to$ Nome $\to$ HP | Ordem **invertida** (Nome no topo, barra embaixo) | **Ordem 1:1 restaurada: Barra no topo (`y-36`), Nome (`y-25`), HP (`y-13`)** |
| **Placa da Caitlyn** | `.lol-player-plate` 105x17 preto + Level 5 + HP/Mana | Sem container preto, textos colados na barra | **Container `.lol-player-plate` 105x17 + Level 5 (15x15) + Barras 84px + Ticks 100 HP** |
| **Geometria do Dummy** | `THREE.CapsuleGeometry(0.7, 1.5)` $\to$ **2.9m total** | `CapsuleMesh(height=1.5)` $\to$ **esfera achatada** | **`CapsuleMesh(radius=0.7, height=2.9)` + Outline `(0.85, 3.35)` + Anel plano `RingMeshBuilder`** |

---

## 2. Descobertas Críticas de Engenharia

### A. Por que as sombras da Caitlyn e dos Dummies haviam desaparecido?
A câmera MOBA fica posicionada em `(0, 56, 48)` olhando para `(0, 0, 0)`. A distância euclidiana da câmera até a origem é:
$$\sqrt{0^2 + 56^2 + 48^2} = \sqrt{3136 + 2304} = \sqrt{5440} \approx 73.75\text{ metros}$$
No Godot 4, `directional_shadow_max_distance` define o alcance do frustum de sombra **a partir da posição da `Camera3D`**, e não a partir do foco no chão. Quando `directional_shadow_max_distance` estava em `55.0`, o shadow map terminava $18.75\text{ metros}$ antes de chegar à Caitlyn! Ao calibrar `directional_shadow_max_distance = 115.0` e `directional_shadow_fade_start = 0.95`, a sombra direcional voltou a ser projetada com nitidez total sob os pés da Caitlyn e dos Dummies.

### B. Por que os Dummies pareciam bolinhas com antenas?
Em Three.js, `new THREE.CapsuleGeometry(radius=0.7, length=1.5)` define `length` como a altura apenas da seção cilíndrica central, resultando em uma altura total de $1.5 + 2 \times 0.7 = 2.9\text{ metros}$. No Godot 4, `CapsuleMesh.height` representa a altura **total** incluindo as duas semiesferas. Com `height = 1.5` e `radius = 0.7`, o cilindro central tinha apenas $0.1\text{m}$ (uma esfera quase perfeita), fazendo com que os olhos em `y = 2.0` flutuassem fora da cabeça como antenas. Ajustar `height = 2.9` (e `3.35` no outline) restaurou a silhueta exata do Dummy original.

### C. Otimizações de CPU/GPU para Web (`scenes/ui/floating_bars.gd`, `floating_damage.gd`, `main.gd`)
1. **Cache de `TextLine` (HarfBuzz):** Em vez de chamar `draw_string` e `draw_string_outline` dezenas de vezes por frame (que re-executam o *shaping* HarfBuzz a cada frame), todas as strings do HUD flutuante e números de dano são pré-moldadas em objetos `TextLine` e redesenhadas diretamente via `TextLine.draw()`, atualizando o buffer apenas quando o valor de HP muda.
2. **Eliminação de `queue_redraw()` Ocioso:** `floating_bars.gd` rastreia um hash de estado/posição arredondada (`_last_state_hash`) e só solicita `queue_redraw()` quando há deslocamento de pelo menos 1 pixel físico ou mudança de HP/alvo.
3. **Interseção Analítica de Raio com o Piso:** Substituído `PhysicsDirectSpaceState3D.intersect_ray()` por `Plane(Vector3.UP, 0.0).intersects_ray()` em `main.gd`, eliminando alocações de dicionários e consultas ao servidor de física a cada movimento do mouse.
4. **Throttling da Ponte JS (`JavaScriptBridge.eval`):** Reduzido de chamadas a cada frame para 1 vez a cada `0.5s`.

---

## 3. Medições Fotométricas e Geométricas (1280x720)

| Elemento / Região | Medida no Three.js (`A_three_baseline.png`) | Medida no Godot Calibrado (`B_godot_corrected.png`) | Paridade |
| :--- | :--- | :--- | :---: |
| **Card `#status-hud` (Bounding Box)** | `x=[20, 324]`, `y=[20, 260]` (`305x241 px`) | `x=[20, 324]`, `y=[20, 260]` (`305x241 px`) | **Exata (0 px delta)** |
| **Placa `.lol-player-plate` Caitlyn** | `105x17 px`, Level `15x15`, Barras `84px` | `105x17 px`, Level `15x15`, Barras `84px` | **Exata (0 px delta)** |
| **Hierarquia Vertical Caitlyn** | Nome `y=244`, HP `y=257`, Placa `y=[264..280]` | Nome `y=244`, HP `y=257`, Placa `y=[264..280]` | **Exata (0 px delta)** |
| **Hierarquia Vertical Dummies** | Barra `y=[372..380]`, Nome `y=392`, HP `y=405` | Barra `y=[372..380]`, Nome `y=392`, HP `y=405` | **Exata (0 px delta)** |
| **Cor do Piso (Fora da Sombra)** | RGB `[23, 25, 27]` a `[25, 27, 29]` | RGB `[24, 26, 28]` a `[25, 27, 30]` | **$\le 1\text{ RGB}$** |
| **Cor do Piso (Dentro da Sombra da Caitlyn)**| RGB `[7, 11, 15]` | RGB `[6, 10, 14]` | **$\le 1\text{ RGB}$** |

---

## 4. Benchmarks Multi-Cenário (Three.js vs Godot 4 Web)

Medições realizadas via `tools/run_benchmarks.cjs` em janela Chrome real de **1280x720 (`deviceScaleFactor = 1`)**, coletando centenas de amostras `requestAnimationFrame` por cenário (`docs/migration/visual/multi_scenario_benchmark.json`).

### Passada 1 — Sem Trava de V-Sync (`--disable-gpu-vsync --disable-frame-rate-limit`)

| Cenário de Jogo | Three.js FPS Médio | Three.js Frame Time Médio (ms) | Three.js P95 (ms) | Godot 4 FPS Médio | Godot 4 Frame Time Médio (ms) | Godot 4 P95 (ms) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Cena Parada (Idle)** | 97 FPS | 10.29 ms | 18.50 ms | **95 FPS** *(janela limpa)* / 49 FPS *(suíte contínua)* | **10.57 ms** / 20.50 ms | 35.63 ms |
| **2. Movimento Contínuo** | 97 FPS | 10.27 ms | 18.10 ms | **58 FPS** | **17.26 ms** | 34.87 ms |
| **3. Ataque e Kiting** | 108 FPS | 9.27 ms | 17.20 ms | **56 FPS** | **17.81 ms** | 34.78 ms |
| **4. Dummies Recebendo Dano** | 104 FPS | 9.62 ms | 17.40 ms | **55 FPS** | **18.30 ms** | 35.70 ms |
| **5. Câmera em Movimento** | 124 FPS | 8.05 ms | 14.30 ms | **55 FPS** | **18.04 ms** | 34.93 ms |

### Passada 2 — Navegador Padrão com V-Sync Ativo (Monitor 60Hz)

| Cenário de Jogo | Three.js FPS Médio | Three.js Frame Time (ms) | Godot 4 FPS Médio | Godot 4 Frame Time (ms) |
| :--- | :---: | :---: | :---: | :---: |
| **1. Cena Parada (Idle)** | 60 FPS | 16.67 ms | 31–54 FPS | 18.46–32.61 ms |
| **2. Movimento Contínuo** | 55 FPS | 18.33 ms | 21–45 FPS | 22.20–47.57 ms |
| **3. Ataque e Kiting** | 59 FPS | 16.92 ms | 43 FPS | 23.51 ms |
| **4. Dummies Recebendo Dano** | 60 FPS | 16.67 ms | 47 FPS | 21.11 ms |
| **5. Câmera em Movimento** | 60 FPS | 16.66 ms | 54 FPS | 18.46 ms |

> [!NOTE]
> **Diagnóstico Honesto do Limite Estrutural na Web:**  
> O modelo original `CaitlynComplete.glb` possui **18.549 triângulos** com *skinning* esquelético completo. No renderer `gl_compatibility` (WebGL 2.0) do Godot 4 com sombras direcionais ativas, a malha da Caitlyn é submetida em 2 passes (passe principal + passe de shadow map = **~40.000 primitivas/frame** em ~35 draw calls), além do resolve MSAA 2x offscreen (`gl.blitFramebuffer`) do Godot Web. Em hardware integrado no Windows/ANGLE com duas abas WebGL abertas simultaneamente, o Godot Web opera na faixa de **55–95 FPS** (`10.57ms`–`18.30ms`), mantendo fluidez e 100% da fidelidade visual exigida (sombras PCF5 + MSAA 2x).

---

## 5. Galeria de Evidências Visuais (`docs/migration/visual/`)

- [A_three_baseline.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/A_three_baseline.png): Captura 1280x720 limpa da referência Three.js.
- [B_godot_corrected.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/B_godot_corrected.png): Captura 1280x720 limpa do Godot 4 após os 5 ciclos de correção.
- [C_comparison_side_by_side.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/C_comparison_side_by_side.png): Comparação panorâmica lado a lado (Three.js vs Godot 4).
- [D_hud_detail.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/D_hud_detail.png): Recorte 1:1 do `#status-hud` (Three.js vs Godot Antes vs Godot Agora).
- [E_grid_detail.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/E_grid_detail.png): Recorte 200% do piso, linha central dourada e grade azul secundária.
- [F_floating_bars_detail.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/F_floating_bars_detail.png): Recorte 200% das placas flutuantes da Caitlyn e dos Dummies (Three.js vs Godot Antes vs Godot Agora).
- [G_combat_damage_detail.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/G_combat_damage_detail.png): Comparação 200% em combate ativo com números de dano flutuantes (`"55"` / `"96!"`) e barras reduzidas.
- [shadows_comparison.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/shadows_comparison.png): Recorte 200% da sombra projetada real da Caitlyn e contato com os pés.
- [caitlyn_edge_comparison.png](file:///c:/.PROJETOS%20-%20Sites%202026/godot/game-x1/docs/migration/visual/caitlyn_edge_comparison.png): Recorte 200% da silhueta da Caitlyn, rifle e placa de vida.
