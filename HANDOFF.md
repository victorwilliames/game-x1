# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Migração integral 1:1 de `game-x0-moba` para Godot 4 — **Pipeline Gráfico, Antialiasing e Calibragem Visual 1:1 Concluídos**. Antialiasing MSAA 2x ativo no WebGL 2.0 (`msaa_3d=1`) eliminando o serrilhamento da silhueta da Caitlyn e estabilizando 100% as linhas finas da arena (sem o borrado do FXAA); Filtragem anisotrópica 4x ativa; Sombras direcionais PCF calibradas com frustum reduzido para 55m e bias de 0.02 (eliminação total de peter-panning); Calibragem fotométrica do piso PBR atingindo `[24, 26, 28]` no Godot vs `[23, 25, 27]` no Three.js ($\Delta \le 1$ RGB); Tipografia Outfit com integer pixel snapping (`pos = pos.round()`). 5/5 suítes automatizadas passando com 0 erros, exportação Web atualizada e composições visuais salvas em `docs/migration/visual/`.  
**Branch:** `port/game-x0-1to1`

## 1. O que o jogador e o avaliador podem verificar agora

1. **Paridade Visual e de Imagem 1:1:**
   - **Antialiasing de Hardware (MSAA 2x):** Bordas do modelo 3D da Caitlyn, rifle e Dummies suaves e definidas, idênticas ao Three.js original, sem perda de nitidez global.
   - **Estabilidade da Grade:** Linhas de 1px contínuas sem quebras ou subpixel aliasing durante a navegação da câmera.
   - **Sombras PCF Acopladas:** Sombra direcional nítida e suave projetada sob os pés da Caitlyn sem descolamento ou frestas (bias 0.02, normal_bias 1.0, alcance 55m).
   - **Piso Ardósia Calibrado:** Valor RGB na tela medido em `[24, 26, 28]` (ardósia escuro profundo com contraste idêntico à linha central dourada `#c29d53`).
   - **Tipografia e UI Nítida:** Fonte `Outfit` rasterizada com contornos pretos de 1px e coordenadas inteiras nas placas flutuantes e no card de status `#status-hud`.
2. **Jogabilidade e Combate 1:1 LoL:**
   - Caitlyn oficial 3D (`CaitlynComplete.glb`, 16.0 m/s, HP 1072, alcance 18m).
   - Ataque básico com windup 0.04s e animação acelerada a 3.5x.
   - Projéteis rosas Hextech a 25.0 m/s (55 dano / 96 crítico).
   - Coronhada melee instantânea a $\le 3.2$ m com faísca amarela.
   - Kiting com bônus de cliques rápidos (+15% a cada stack até +45%).
   - Dummies estático e móvel (600 HP, anel roxo de 3m, outline vermelho, flash e respawn em 3.0s).
   - Câmera LoL: FOV 38°, offset (0, 56, 48), folga do cursor no modo travado, edge pan, arrasto MMB e limites $\pm 38$.

## 2. Arquivos alterados / criados

- `project.godot`: configuração de `msaa_3d=1`, `anisotropic_filtering_level=2`, `screen_space_aa=0`, resolução de sombras 2048 PCF e snapping 2D.
- `scenes/main.tscn`: calibragem fotométrica do piso PBR (`albedo_color = Color(0.026, 0.040, 0.055, 1)`, `metallic_specular = 0.3`) e ajuste da sombra direcional (alcance 55m, bias 0.02, normal_bias 1.0).
- `scenes/arena/grid_helper.gd`: calibragem das cores unshaded para eixos centrais dourados e células azuis.
- `scenes/ui/floating_bars.gd`: integer pixel snapping (`pos = pos.round()`) nas placas flutuantes da Caitlyn e dos Dummies.
- `scenes/main.gd`: bridge JS estendida para expor `window._gamex1_engine_fps` e frame time no WebGL.
- `tools/visual_capture.cjs`: flags anti-throttling para Chrome headless e medição automatizada de frame time.
- `docs/migration/ART_DIRECTION.md`: documentação técnica completa do pipeline gráfico, matriz de testes MSAA e comparativos.
- `docs/migration/PARITY_MATRIX.md` & `REFERENCE_BASELINE.md`: matriz atualizada com status 1:1 de todos os componentes.
- `docs/migration/visual/`: entregáveis visuais obrigatórios:
  - `A_three_baseline.png`: captura do Three.js original.
  - `B0_godot_before.png`: captura do Godot inicial antes das correções.
  - `B_godot_corrected.png`: captura do Godot final calibrado 1:1.
  - `C_comparison_side_by_side.png`: composição panorâmica 2560x780 comparando Three.js vs Godot Calibrado.
  - `caitlyn_edge_comparison.png`: zoom 300% das bordas da Caitlyn avaliando MSAA 0x vs 2x vs Three.js.
  - `D_hud_detail.png`: detalhe comparativo do Card `#status-hud` e fontes.
  - `E_grid_detail.png`: detalhe comparativo da grade e contraste do piso.
  - `shadows_comparison.png`: detalhe comparativo das sombras projetadas.
  - `msaa_0x.png`, `msaa_2x.png`, `msaa_4x.png`, `msaa_8x.png`: matriz de benchmarks MSAA.

## 3. Estado das validações

- **verified:** Suíte quíntupla (`scripts/test.ps1`) com 100% de sucesso (código de saída 0):
  - 1/5: Import & parse do editor headless.
  - 2/5: Smoke check de 60 frames.
  - 3/5: Movimento determinístico e parada sem overshoot (`test_movement.gd`).
  - 4/5: 7 verificações de câmera e limites (`test_camera.gd`).
  - 5/5: 7 verificações de combate, dummies, projéteis, kiting e targeting (`test_combat.gd`).
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerando pacote atualizado em `build/web/`.
- **verified:** Servidor web ativo servindo a versão 1:1 atualizada em `http://localhost:8080/`.
- **verified:** Medições objetivas de paridade de cor no piso confirmando $\Delta \le 1$ RGB em relação ao Three.js.

## 4. Próxima ação / comando

1. Avaliar as evidências visuais em `docs/migration/visual/C_comparison_side_by_side.png`.
2. Fazer commit e push exclusivamente na branch `port/game-x0-1to1`.
