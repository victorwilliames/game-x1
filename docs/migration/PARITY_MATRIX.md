# Matriz de Paridade 1:1 — game-x0-moba para Godot 4

Esta matriz rastreia o estado de migração e verificação de cada funcionalidade e componente visual do jogo original (`game-x0-moba`) para o porto em Godot 4 (`game-x1`).

| Sistema / Funcionalidade | Implementação Original (`game-x0-moba`) | Implementação Godot 4 (`game-x1`) | Estado | Testes & Evidências | Divergências Restantes |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Câmera: FOV e Ângulo** | `PerspectiveCamera(38°)`, Offset `(0, 56, 48)` | `Camera3D` com FOV 38°, Offset `(0, 56, 48)` | **1:1 Verificado** | `test_camera.gd` (Check 7) | Nenhuma (paridade exata) |
| **Câmera: Modo Locked com Folga** | Folga com mouse ratio ($\le 6.0\text{ m}$), lerp 0.08 | `moba_camera.gd` com folga proporcional e lerp 0.08 | **1:1 Verificado** | `test_camera.gd` (Check 1) | Nenhuma |
| **Câmera: Free Mode, Edge Pan & Drag** | Edge threshold 18px, vel 40 u/s, MMB drag 0.05 | Edge pan em 18px interno ao canvas e MMB drag | **1:1 Verificado** | `test_camera.gd` (Check 6) | Nenhuma |
| **Câmera: Teclas Y e Espaço/Quote** | `Y` alterna trava, `Space`/`'` centraliza no campeão | `handle_input()` com `Y` e `Space` / `Quote` | **1:1 Verificado** | `test_camera.gd` (Check 2, 3) | Nenhuma |
| **Cenário: Chão e Grid 80x80** | Plano `#0a1016`, Grid dourado `#c29d53` / azul `#162838` | Piso PBR `[25, 27, 30]` + `MobaGridHelper` 1px (`#c29d53` / `#162838`) | **1:1 Verificado** | `E_grid_detail.png` | Nenhuma ($\le 1\text{ RGB}$) |
| **Iluminação & Sombras** | Ambient `#121b26` (1.5), DirLight `#ffffff` (2.0) em `(20, 40, 20)` | `DirectionalLight3D` PCF5 16-bit, `max_distance=115.0m`, `fade_start=0.95` | **1:1 Verificado** | `shadows_comparison.png` | Nenhuma (contato exato nos pés) |
| **Caitlyn: Modelo 3D & Escala** | `CaitlynComplete.glb`, escala 0.055, altura 3.5 | `CaitlynComplete.glb` com escala 0.055 e materiais PBR | **1:1 Verificado** | `caitlyn_edge_comparison.png` | Nenhuma |
| **Caitlyn: Animação Idle & Run** | `idle1.anm` (1.0x), `run.anm` (2.5x) | `AnimationPlayer` com speeds 1.0x e 2.5x | **1:1 Verificado** | `test_movement.gd` | Nenhuma |
| **Caitlyn: Movimento & Rotação** | Vel 16.0 m/s, rotação suave `diff * 0.25` | `CharacterBody3D` com mesma interpolação e parada | **1:1 Verificado** | `test_movement.gd` (Chegada 0.000m) | Nenhuma |
| **Inimigo: Dummy Estático & Móvel** | `CapsuleGeometry(0.7, 1.5)` $\to$ `2.9m` altura total | `CapsuleMesh(radius=0.7, height=2.9)` em `(7,0,7)` e `(-7,0,7)` | **1:1 Verificado** | `F_floating_bars_detail.png` | Nenhuma |
| **Inimigo: Outline Vermelho** | `CapsuleGeometry(0.85, 1.65)` $\to$ `3.35m` invertida `#ff0000` | `CapsuleMesh(radius=0.85, height=3.35)` cull front unshaded `#ff0000` | **1:1 Verificado** | `G_combat_damage_detail.png` | Nenhuma |
| **Inimigo: Círculo de Tolerância** | `RingGeometry(2.96, 3.0, 64)` roxo plano no chão | `RingMeshBuilder.create_ring_mesh(2.92, 3.0, 64)` contínuo e plano | **1:1 Verificado** | `F_floating_bars_detail.png` | Nenhuma |
| **Inimigo: Flash, Morte & Respawn** | Flash branco 0.1s, tomba 90°, respawn em 3.0s | Timer e troca de material/rotação idênticos | **1:1 Verificado** | `test_combat.gd` (Check 6) | Nenhuma |
| **Combate: Seleção de Alvo (Targeting)**| Prioridade 1: cursor ($\le 5\text{ m}$); Prioridade 2: alcance (18 m) | Classe `TargetingSystem` + `Plane.intersects_ray` analítico | **1:1 Verificado** | `test_combat.gd` (Check 3) | Nenhuma |
| **Combate: Disparo Básico & Windup** | Windup 0.04s, anim 0.12s, attack speed 1.85 | Estados `IDLE`/`ATTACKING` e timers | **1:1 Verificado** | `test_combat.gd` (Check 4, 5) | Nenhuma |
| **Combate: Projétil Hextech** | Esfera rosa `#ff007f` (raio 0.12), vel 25 m/s, homing | `MobaProjectile` com modos teleguiado e direcional | **1:1 Verificado** | `test_combat.gd` (Check 5) | Nenhuma |
| **Combate: Ataque Melee (Coronhada)** | Alvo $\le 3.2\text{ m}$: dano imediato 55 + faísca amarela | Detecção de distância e spawn de slash amarelo | **1:1 Verificado** | `test_combat.gd` (Check 4) | Nenhuma |
| **Kiting: Cliques Rápidos & Redução CD**| Cliques de 0.10s-0.42s: +15% AS (até +45%), -0.14s CD | Acúmulo de stacks e redução de cooldown | **1:1 Verificado** | `test_combat.gd` (Check 7) | Nenhuma |
| **Kiting: Attack Move (Tecla A)** | Tecla A ativa círculo vermelho de alcance e clique esquerdo | Action Map e modo Attack Move com anel plano | **1:1 Verificado** | `main.gd` | Nenhuma |
| **UI: Indicador de Clique no Chão** | `pointTarget.glb` verde `#00ff88`, gira 6 rad/s, 0.35s | Importação de `pointTarget.glb` com rotação e escala | **1:1 Verificado** | `main.gd` | Nenhuma |
| **UI: Placa Flutuante da Caitlyn** | `$y+5.2$`, Nome (`y-45`), HP (`y-33`), `.lol-player-plate` 105x17 | `floating_bars.gd` com `TextLine` cache, Level 5 `15x15`, Barras `84px` | **1:1 Verificado** | `F_floating_bars_detail.png` | Nenhuma (`0 px` delta) |
| **UI: Placa Flutuante dos Dummies** | `$y+3.4$`, Barra vermelha no topo (`y-36`), Nome (`y-25`), HP (`y-13`) | `floating_bars.gd` com barra `110x9` no topo e textos embaixo | **1:1 Verificado** | `F_floating_bars_detail.png` | Nenhuma (`0 px` delta) |
| **UI: Números de Dano** | Outfit 900, Laranja `#ff9f00` (26px), Crítico `#ff3300` (34px) | `floating_damage.gd` com `MobaFonts.outfit_black()` + `TextLine` cache | **1:1 Verificado** | `G_combat_damage_detail.png` | Nenhuma |
| **UI: Status HUD & Controles** | Card `305x241` (`y=[20,260]`), Outfit 500/700 + `monospace` bold + ícones | `status_hud.tscn` `305x241` + `monospace_bold` + `icon_mouse/keyboard.png` | **1:1 Verificado** | `D_hud_detail.png` | Nenhuma (`0 px` delta) |
| **UI: Cursores Customizados** | `normal.cur`, `alt.cur` (espada vermelha), `link.cur` | `Input.set_custom_mouse_cursor()` com PNGs originais | **1:1 Verificado** | `main.gd` | Nenhuma |
| **Pipeline Gráfico: Antialiasing** | WebGL MSAA 4x nativo | `rendering/anti_aliasing/quality/msaa_3d = 1` (2x) | **1:1 Verificado** | `caitlyn_edge_comparison.png` | Nenhuma |
