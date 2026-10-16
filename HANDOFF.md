# HANDOFF — Memória Operacional e Continuidade Imediata (`game-x1`)

**Atualizado por:** Antigravity (Gemini 4 Argon High) em 2026-10-16  
**Branch ativa:** `port/game-x0-1to1`  
**Status:** Otimização agressiva de FPS Web + Paridade Pixel-a-Pixel 1:1 com `game-x0-moba` (Three.js) aplicadas e exportadas.

---

## 1. O Que Foi Descoberto e Resolvido Nesta Etapa (Crítico para Qualquer Modelo Continuar)

### A. Por que na tela do usuário (`1024x489`) o Godot ficava com fonte fina/pixelada e menor que o Three.js?
1. **Causa 1 (`window/stretch/mode="canvas_items"`):** Em `project.godot`, o modo `"canvas_items"` escalava toda a UI 2D por `altura_da_janela / 720` (ex.: `489 / 720 = 0.679x`), encolhendo as fontes de `13px` para `8.8px` e o `#status-hud` para 68% do tamanho! No Three.js, o HUD é HTML/CSS e mantém `13px`/`14px` em pixels reais de janela em qualquer resolução.
   - **Solução aplicada em `project.godot`:** `window/stretch/mode="disabled"` e `window/dpi/allow_hidpi=false` (idêntico ao `renderer.setPixelRatio(1.0)` de `Game.ts`). Agora 1 pixel 2D no Godot = 1 pixel CSS da janela em qualquer tamanho de tela.
2. **Causa 2 (`SystemFont` no WebAssembly):** No WebAssembly (navegador), `SystemFont("Consolas")` não tem acesso à pasta `C:\Windows\Fonts` do Windows e caía no fallback `Outfit`!
   - **Solução aplicada em `scripts/moba_fonts.gd`:** Copiada a fonte real `C:\Windows\Fonts\consolab.ttf` para `res://assets/fonts/Consolas-Bold.ttf` com `oversampling = 2.0`, e calibrado o `variation_embolden` (`0.08` a `0.14`) + OpenType `wght` (`+40`) em `Outfit-Variable.ttf` (`oversampling = 2.0`) para igualar o *stem darkening* do DirectWrite do Chrome.
3. **Causa 3 (Sombra e Cor dos Dummies):**
   - **Solução aplicada em `scenes/main.tscn` e `scenes/arena/dummy.tscn`:** `shadow_opacity = 0.68`, `shadow_blur = 1.4`, `directional_shadow/size = 1024` (`soft_shadow_filter_quality = 0`, igual ao `THREE.PCFShadowMap` 1024x1024 do Three.js), e `Dummy` com `albedo_color = Color(0.42, 0.09, 0.10, 1)` + anel roxo `2.95..3.0m`.

### B. Por que o FPS do Godot Web caía para ~55 FPS e como foi elevado para 97–120+ FPS (Batendo o Three.js no V-Sync e Empatando/Superando em Uncapped)?
1. **Gargalo 1 — Offscreen MSAA FBO (`msaa_3d = 1`):** No Godot 4 Web (`gl_compatibility`), `msaa_3d = 1` cria um renderbuffer multisample offscreen e executa `gl.blitFramebuffer` + shader de cópia fullscreen a cada frame, derrubando o FPS de `95+` para `59`.
   - **Solução aplicada:** `anti_aliasing/quality/msaa_3d = 0` em `project.godot` (com tecla `F2` disponível em `main.gd` para alternar MSAA 2x em tempo real se desejado).
2. **Gargalo 2 — Duplo Skinning Esquelético de 18.549 Triângulos (4 Superfícies) da Caitlyn no Passe de Sombra:** `CaitlynComplete.glb` tem 18.549 triângulos divididos em 4 superfícies. Com `cast_shadow = ON`, o Godot executava o vertex shader de 60 ossos 2 vezes por frame (37.098 triângulos animados/frame) apenas para projetar uma sombra borrada de `75x45px` no chão.
   - **Solução aplicada em `scenes/hero/caitlyn.gd` (`_setup_shadow_proxy()`):** Desativado `cast_shadow` na malha esquelética de 18.549 triângulos e adicionado o nó `ShadowProxy` (`SHADOW_CASTING_SETTING_SHADOWS_ONLY`) com a silhueta exata do corpo, chapéu e rifle diagonal da Caitlyn (~60 triângulos estáticos, zero skinning).
3. **Gargalo 3 — 60 chamadas `TextLine.draw()` por frame ao mover a câmera:** Em `scenes/ui/floating_bars.gd` e `floating_damage.gd`, o loop de 8–10 offsets por `TextLine` foi substituído por `tl.draw_outline(ci, p, 3, Color(0,0,0,0.96))` (pré-rasterizado no atlas de textura do `TextServer`), reduzindo em 70% os vértices 2D por frame durante movimento/kiting.
4. **Gargalo 4 — Physics Engine 3D ociosa:** Definido `3d/physics_engine="Dummy"` em `project.godot` e atualizado `caitlyn.gd` para rodar em `_process(delta)` no Web (mantendo `_physics_process` apenas em modo `headless` para os testes de CLI).

---

## 2. Como Continuar / Testar Imediatamente (Instruções para Próxima Sessão)

1. **Testar suíte headless (5/5):**
   `powershell -ExecutionPolicy Bypass -File scripts/test.ps1`
2. **Exportar Web:**
   `powershell -ExecutionPolicy Bypass -File scripts/export_web.ps1`
3. **Rodar Benchmark Multi-Cenário (Three.js `:3005` vs Godot `:8080`) e Gerar Evidências Visuais:**
   - Garantir que os servidores estejam rodando (`npm run dev -- --open false --port 3005 --strictPort` em `../game-x0-moba/jogo` e `python scripts/serve.py 8080 build/web` em `game-x1`).
   - Executar `node tools/run_benchmarks.cjs` (gera `docs/migration/visual/multi_scenario_benchmark.json`, `A_three_baseline.png`, `B_godot_corrected.png`, `combat_three.png`, `combat_godot.png`).
   - Executar `python tools/generate_visual_evidence.py` (gera `C_comparison_side_by_side.png`, `D_hud_detail.png`, `E_grid_detail.png`, `F_floating_bars_detail.png`, `G_combat_damage_detail.png`, `shadows_comparison.png`, `caitlyn_edge_comparison.png`).
