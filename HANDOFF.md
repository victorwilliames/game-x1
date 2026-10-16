# HANDOFF — Memória Operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-16  
**Situação:** Migração integral 1:1 de `game-x0-moba` para Godot 4 — **Ciclos 1 a 5 Concluídos (Tipografia, Placas Flutuantes 1:1, `#status-hud` Pixel-Exact, Geometria/Sombras 3D e Benchmarks Multi-Cenário Web)**.
- **Ciclo 1 (Tipografia):** Eixo OpenType `wght` nativo em `Outfit-Variable.ttf` (`500`, `700`, `800`, `900`) + `hinting=1` (`FONT_HINTING_LIGHT`) + `subpixel_positioning=1` (`AUTO`), além de `MobaFonts.monospace_bold()` (`Consolas`/`Courier New` 700) para os `span` de Status e FPS no HUD, sem outline artificial no card.
- **Ciclo 2 (Placas Flutuantes):** Reconstrução completa de `scenes/ui/floating_bars.gd` com cache de `TextLine` (HarfBuzz pré-moldado), sombra CSS de 4 cantos + drop-shadow desenhada **atrás** dos glifos, container preto `.lol-player-plate` (`105x17 px`, Level 5 `15x15`, barras `84px` com ticks de `100 HP`) na Caitlyn (`y+5.2`) e hierarquia 1:1 restaurada nos Dummies (`y+3.4`: barra vermelha `110x9` no **topo** em `y-36`, Nome no meio em `y-25`, HP embaixo em `y-13`, zero colisão).
- **Ciclo 3 (`#status-hud` e Botão Fullscreen):** Card calibrado com bounding box exata `305x241 px` (`x=[20, 324], y=[20, 260]`), ícones reais `icon_mouse.png` (`10x15`) e `icon_keyboard.png` (`14x11`) extraídos 1:1 com filtro `NEAREST`, e geometria SVG 1:1 em `fullscreen_button.gd`.
- **Ciclo 4 (Cena 3D, Dummies, Sombras e Grid):** Corrigida a altura das cápsulas dos Dummies em `dummy.tscn` (`height = 2.9` para `CapsuleGeometry(0.7, 1.5)` e `3.35` no outline), anel roxo plano contínuo via `RingMeshBuilder.create_ring_mesh(2.92, 3.0, 64)`, e restaurada a projeção de sombras direcionais (`directional_shadow_max_distance = 115.0`, `fade_start = 0.95`, PCF5 16-bit, cobrindo a distância câmera-origem de $73.75\text{m}$).
- **Ciclo 5 (Otimização Web & Benchmarks Multi-Cenário):** Eliminado `queue_redraw()` ocioso, *shaping* HarfBuzz por frame (`TextLine` cache), raycast físico por frame (`Plane.intersects_ray` analítico) e `JavaScriptBridge.eval` por frame; executada bateria multi-cenário (`tools/run_benchmarks.cjs`) e gerados todos os compósitos de evidência em `docs/migration/visual/`.  
**Branch:** `port/game-x0-1to1`

## 1. Links do Projeto e Referências

- **Repositório Destino (Godot 4):** [https://github.com/victorwilliames/game-x1](https://github.com/victorwilliames/game-x1)
  - **Branch ativa:** `port/game-x0-1to1`
  - **Diretório local:** `C:\.PROJETOS - Sites 2026\godot\game-x1`
  - **Servidor Web Local (Godot):** [http://localhost:8080/](http://localhost:8080/)
- **Repositório de Referência (Three.js):** [https://github.com/victorwilliames/game-x0-moba](https://github.com/victorwilliames/game-x0-moba)
  - **Jogo publicado de referência:** [https://victorwilliames.github.io/game-x0-moba/](https://victorwilliames.github.io/game-x0-moba/)
  - **Diretório local:** `C:\.PROJETOS - Sites 2026\godot\game-x0-moba\jogo`
  - **Servidor Dev Local (Three.js):** [http://localhost:3005/](http://localhost:3005/)

## 2. Arquivos Alterados / Criados Neste Marco

- `assets/fonts/Outfit-Variable.ttf.import`
- `assets/ui/icons/icon_mouse.png`, `assets/ui/icons/icon_keyboard.png`
- `scripts/moba_fonts.gd`
- `scenes/ui/floating_bars.gd`
- `scenes/ui/floating_damage.gd`
- `scenes/ui/status_hud.gd`, `scenes/ui/status_hud.tscn`
- `scenes/ui/fullscreen_button.gd`
- `scenes/arena/dummy.gd`, `scenes/arena/dummy.tscn`
- `scenes/arena/grid_helper.gd`
- `scenes/main.gd`, `scenes/main.tscn`, `project.godot`
- `tools/generate_visual_evidence.py`, `tools/run_benchmarks.cjs`, `tools/capture_combat.cjs`
- `docs/migration/ART_DIRECTION.md`, `docs/migration/PARITY_MATRIX.md`, `docs/migration/visual/*`

## 3. Estado das Validações

- **verified:** Suíte quíntupla (`scripts/test.ps1`) com 100% de sucesso (5/5 suítes passando, código de saída 0).
- **verified:** Exportação Web (`scripts/export_web.ps1`) atualizada em `build/web/`.
- **verified:** Evidências visuais lado a lado e em zoom 200% (`A_three_baseline.png`, `B_godot_corrected.png`, `C_comparison_side_by_side.png`, `D_hud_detail.png`, `E_grid_detail.png`, `F_floating_bars_detail.png`, `G_combat_damage_detail.png`, `shadows_comparison.png`, `caitlyn_edge_comparison.png`) e benchmark multi-cenário (`multi_scenario_benchmark.json`) gerados e inspecionados.

## 4. Próxima Ação Recomendada

1. Revisão visual pelo proprietário das imagens comparativas geradas em `docs/migration/visual/`.
2. Se desejado ganho adicional de FPS Web em GPUs integradas, avaliar decimação opcional de LOD para o passe de sombra de `CaitlynComplete.glb` (atualmente 18.549 triângulos submetidos 2x por frame).
