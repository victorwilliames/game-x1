# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Migração integral 1:1 de `game-x0-moba` para Godot 4 — **Correção Visual Obrigatória Concluída com Fidelidade 1:1 ao Anexo 2 (Three.js)**. Chão PBR escuro `#0a1016` com `MobaGridHelper` em linhas finas de 1px (`Mesh.PRIMITIVE_LINES`), eixos centrais dourados `#c29d53` e células `#162838`; Card `#status-hud` idêntico com fundo translúcido escuro, borda dourada, cantos arredondados, fonte `Outfit` e ícones pixel-perfect para mouse e teclado; Botão circular Hextech de Tela Cheia no canto superior direito; Indicadores em anel 2D plano (`RingMeshBuilder`); Barras de vida e placas flutuantes calibradas com contornos nítidos de 1px; Telemetria transferida para overlay F3. 5/5 suítes automatizadas passando, exportação Web atualizada e validações visuais registradas.  
**Branch:** `port/game-x0-1to1`

## 1. O que o jogador pode fazer agora

1. **Jogar com a Caitlyn oficial 3D:**
   - Modelo oficial `CaitlynComplete.glb` em escala 0.055 com animações sincronizadas (`idle1_anm`, `run_anm` a 2.5x e `attack1_anm` acelerada a 3.5x).
   - Movimentação responsiva a 16.0 m/s com rotação suave via clique direito.
   - Indicador de clique verde animado com o modelo `pointTarget.glb` que gira e decai de escala.
2. **Combate 1:1 contra Dummies:**
   - Dois Dummies na arena: Estático em `(7, 0, 7)` e Móvel em `(-7, 0, 7)` patrulhando em zigue-zague a 2.5 m/s.
   - Disparo teleguiado e direcional a 25.0 m/s com esfera rosa Hextech (`#ff007f`) causando 55 de dano (crítico 96).
   - Ataque Melee (Coronhada de rifle): a $\le 3.2$ m desfere dano instantâneo com faísca amarela na altura do peito.
   - Tolerância de clique de 3.0 m: clicar no chão próximo ao dummy (dentro do círculo roxo) trava o alvo automaticamente.
   - Outline vermelho grosso no hover do mouse e no alvo selecionado.
   - Dummy pisca em branco brilhante por 0.1s ao receber dano, cai ao morrer e ressurge após 3.0s.
3. **Kiting Mecânico estilo LoL:**
   - Cliques rápidos ritmados entre 0.10s e 0.42s acumulam até +45% de attack speed bônus (+15% por stack).
   - Cliques rápidos durante o cooldown pós-windup reduzem o tempo restante em 0.14s por clique.
4. **Interface e Apresentação Visual 1:1:**
   - **Piso e Grade:** Piso escuro PBR `#0a1016` recebendo sombras; grade fina de 1px nativa (`Mesh.PRIMITIVE_LINES`) a $y=0.01$ com eixos dourados `#c29d53` e células `#162838`, sem shaders borrados ou grossos.
   - **Status HUD:** Card translúcido escuro `rgba(6, 12, 19, 0.85)` com borda dourada `#c29d53` (40%), cantos arredondados (8px), divisória dourada, fonte `Outfit` com pesos médio/negrito e ícones fiéis para mouse e teclado.
   - **Botão Hextech de Tela Cheia:** Botão circular dourado 42x42px no canto superior direito que expande a aba do navegador para fullscreen via `requestFullscreen()`.
   - **Placa LoL da Caitlyn e Dummies:** Placa posicionada acima da cabeça ($y+6.1$ / $y+3.8$) com nível 5, mana, barras de 100 HP, textos nítidos em branco e ciano com contorno de 1px.
   - **Indicadores 2D Planos:** Alcance de ataque e marcador de alvo gerados como superfícies 2D planas (`RingMeshBuilder`) no nível do piso sem volume 3D.
   - **Overlay de Telemetria:** Painel técnico de desenvolvedor com draw calls, primitivas e FPS acionável por tecla `F3`.

## 2. Arquivos alterados / criados

- `scenes/arena/grid_helper.gd`: gerador 1:1 do `THREE.GridHelper(80, 40, '#c29d53', '#162838')` com primitivas de linha de 1 pixel.
- `scripts/ring_mesh_builder.gd`: utilitário para gerar geometrias de anel 2D planas (`THREE.RingGeometry`) para os indicadores no chão.
- `scenes/ui/status_hud.gd` & `scenes/ui/status_hud.tscn`: recriação do card `#status-hud` com fonte `Outfit`, StyleBoxFlat dourado e ícones de input.
- `scenes/ui/fullscreen_button.gd`: botão circular Hextech com ícone de 4 cantos e bridge de tela cheia para Web.
- `assets/fonts/Outfit-Variable.ttf` & `OFL-Outfit.txt`: fonte oficial do projeto de referência.
- `assets/ui/icons/icon_mouse.png` & `icon_keyboard.png`: ícones de periféricos para o HUD de controles.
- `scenes/ui/floating_bars.gd`: ajuste de layout e elevações para a placa LoL da Caitlyn e Dummies, usando fonte Outfit e contorno de 1px.
- `scenes/ui/floating_damage.gd`: aplicação da fonte Outfit nos números de dano flutuantes.
- `scenes/main.gd` & `main.tscn`: substituição do shader antigo de chão pelo piso PBR + `MobaGridHelper`, integração do `StatusHUD`, botão de tela cheia e alternância F3.
- `scenes/arena_grid.gdshader`: removido (obsoleto).
- `tools/visual_capture.cjs`: harness automatizado de captura Puppeteer com Chrome normalizado em 1280x720.
- `docs/migration/visual/`: capturas e comparações lado a lado (`A_three_baseline.png`, `B0_godot_before.png`, `B_godot_corrected.png`, `C_comparison_side_by_side.png`, `D_hud_detail.png`, `E_grid_detail.png`).

## 3. Estado das validações

- **verified:** Suíte quíntupla (`scripts/test.ps1`) com código de saída 0:
  - 1/5: Import & parse do editor headless.
  - 2/5: Smoke check de 60 frames.
  - 3/5: Movimento determinístico e parada sem overshoot (`test_movement.gd`).
  - 4/5: 7 verificações de câmera e limites (`test_camera.gd`).
  - 5/5: 7 verificações de combate, dummies, projéteis, kiting e targeting (`test_combat.gd`).
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerando pacote atualizado em `build/web/`.
- **verified:** Servidor web ativo servindo a versão 1:1 atualizada em `http://localhost:8080/`.
- **verified:** Captura automatizada via Puppeteer gerando `B_godot_corrected.png` e comprovando paridade visual direta com `A_three_baseline.png`.

## 4. Próxima ação / comando

1. Avaliar as capturas lado a lado em `docs/migration/visual/C_comparison_side_by_side.png`.
2. Fazer commit e push exclusivamente na branch `port/game-x0-1to1`.
