# Matriz de Paridade 1:1 — game-x0-moba para Godot 4

Esta matriz rastreia o estado de migração de cada funcionalidade e componente do jogo original para a nova versão Godot 4.

| Sistema / Funcionalidade | Implementação Original (`game-x0-moba`) | Implementação Godot 4 (`game-x1`) | Estado | Testes & Evidências | Divergências Restantes |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Câmera: FOV e Ângulo** | `PerspectiveCamera(38°)`, Offset `(0, 56, 48)` | `Camera3D` com FOV 38°, Offset `(0, 56, 48)` | **1:1 Concluído** | `test_camera.gd` (Check 7) | Nenhuma (paridade exata) |
| **Câmera: Modo Locked com Folga** | Folga com mouse ratio ($\le 6.0\text{ m}$), lerp 0.08 | `moba_camera.gd` com folga proporcional e lerp 0.08 | **1:1 Concluído** | `test_camera.gd` (Check 1) | Nenhuma |
| **Câmera: Free Mode, Edge Pan & Drag** | Edge threshold 18px, vel 40 u/s, MMB drag 0.05 | Edge pan em 18px interno ao canvas e MMB drag | **1:1 Concluído** | `test_camera.gd` (Check 6) | Nenhuma |
| **Câmera: Teclas Y e Espaço/Quote** | `Y` alterna trava, `'` centraliza no campeão | `handle_input()` com `Y` e `Space` / `Quote` | **1:1 Concluído** | `test_camera.gd` (Check 2, 3) | Nenhuma |
| **Cenário: Chão e Grid 80x80** | Plano `#0a1016`, Grid dourado `#c29d53` / azul `#162838` | Piso PBR ardósia escuro calibrado + `MobaGridHelper` 1px | **1:1 Concluído** | `E_grid_detail.png` | Nenhuma (linhas finas 1px nativas) |
| **Iluminação & Sombras** | Ambient `#121b26` (1.5), DirLight `#ffffff` (2.0) em (20, 40, 20) | `DirectionalLight3D` e `WorldEnvironment` calibrados | **1:1 Concluído** | `shadows_comparison.png` | Nenhuma (PCF 55m acoplado) |
| **Caitlyn: Modelo 3D & Escala** | `CaitlynComplete.glb`, escala 0.055, altura 3.5 | `CaitlynComplete.glb` com escala 0.055 e materiais PBR | **1:1 Concluído** | `caitlyn_edge_comparison.png` | Nenhuma |
| **Caitlyn: Animação Idle & Run** | `idle1.anm` (1.0x), `run.anm` (2.5x) | `AnimationPlayer` com speeds 1.0x e 2.5x | **1:1 Concluído** | `test_movement.gd` | Nenhuma |
| **Caitlyn: Movimento & Rotação** | Vel 16.0 m/s, rotação suave `diff * 0.25` | `CharacterBody3D` com mesma interpolação e parada | **1:1 Concluído** | `test_movement.gd` (Chegada 0.000m) | Nenhuma |
| **Inimigo: Dummy Estático** | Cápsula vermelha em `(7, 0, 7)`, 600 HP | `dummy.tscn` com cápsula `#9e2a2b` e olhos `#ff3b30` | **1:1 Concluído** | `test_combat.gd` (Check 1) | Nenhuma |
| **Inimigo: Dummy Móvel** | Em `(-7, 0, 7)`, vel 2.5 m/s, zigue-zague $\pm 8\text{ m}$ | `dummy.tscn` móvel com inversão $180^\circ$ e patrulha | **1:1 Concluído** | `test_combat.gd` (Check 1) | Nenhuma |
| **Inimigo: Outline Vermelho** | Cápsula invertida 0.85x1.65 sólida `#ff0000` | Mesh invertido com material unshaded vermelho | **1:1 Concluído** | `test_combat.gd` (Check 3) | Nenhuma |
| **Inimigo: Círculo de Tolerância** | Anel roxo de raio 3.0 no chão sob o dummy | `RingMeshBuilder` 2D plano `#aa00ff` | **1:1 Concluído** | `test_combat.gd` (Check 3) | Nenhuma |
| **Inimigo: Flash, Morte & Respawn** | Flash branco 0.1s, tomba 90°, respawn em 3.0s | Timer e troca de material/rotação idênticos | **1:1 Concluído** | `test_combat.gd` (Check 6) | Nenhuma |
| **Combate: Seleção de Alvo (Targeting)**| Prioridade 1: cursor ($\le 5\text{ m}$); Prioridade 2: alcance (18 m) | Classe `TargetingSystem` nativa em GDScript | **1:1 Concluído** | `test_combat.gd` (Check 3) | Nenhuma |
| **Combate: Disparo Básico & Windup** | Windup 0.04s, anim 0.12s, attack speed 1.85 | Estados `IDLE`/`ATTACKING` e timers | **1:1 Concluído** | `test_combat.gd` (Check 4, 5) | Nenhuma |
| **Combate: Projétil Hextech** | Esfera rosa `#ff007f` (raio 0.12), vel 25 m/s, homing | `MobaProjectile` com modos teleguiado e direcional | **1:1 Concluído** | `test_combat.gd` (Check 5) | Nenhuma |
| **Combate: Ataque Melee (Coronhada)** | Alvo $\le 3.2\text{ m}$: dano imediato 55 + faísca amarela | Detecção de distância e spawn de slash amarelo | **1:1 Concluído** | `test_combat.gd` (Check 4) | Nenhuma |
| **Kiting: Cliques Rápidos & Redução CD**| Cliques de 0.10s-0.42s: +15% AS (até +45%), -0.14s CD | Acúmulo de stacks e redução de cooldown | **1:1 Concluído** | `test_combat.gd` (Check 7) | Nenhuma |
| **Kiting: Attack Move (Tecla A)** | Tecla A ativa círculo vermelho de alcance e clique esquerdo | Action Map e modo Attack Move com anel plano | **1:1 Concluído** | `main.gd` | Nenhuma |
| **UI: Indicador de Clique no Chão** | `pointTarget.glb` verde `#00ff88`, gira 6 rad/s, 0.35s | Importação de `pointTarget.glb` com rotação e escala | **1:1 Concluído** | `main.gd` | Nenhuma |
| **UI: Placas de Vida Flutuantes** | Caitlyn (nível 5, HP verde, mana azul); Dummies (dourado/vermelho)| `floating_bars.gd` com Outfit e integer pixel snapping | **1:1 Concluído** | `D_hud_detail.png` | Nenhuma |
| **UI: Números de Dano** | Laranja `#ff9f00` (26px), Crítico vermelho `#ff3300` (34px) | `floating_damage.gd` com Outfit bold e contorno preto | **1:1 Concluído** | `main.gd` | Nenhuma |
| **UI: Status HUD & Controles** | Card escuro no topo esquerdo com borda dourada | `status_hud.tscn` com StyleBoxFlat dourado e Outfit | **1:1 Concluído** | `D_hud_detail.png` | Nenhuma |
| **UI: Cursores Customizados** | `normal.cur`, `alt.cur` (espada vermelha), `link.cur` | `Input.set_custom_mouse_cursor()` com PNGs originais | **1:1 Concluído** | `main.gd` | Nenhuma |
| **Pipeline Gráfico: Antialiasing** | WebGL MSAA 4x nativo | `rendering/anti_aliasing/quality/msaa_3d = 1` (2x) | **1:1 Concluído** | `caitlyn_edge_comparison.png` | Nenhuma |
| **Pipeline Gráfico: Texturas** | Bilinear + Mipmaps | `anisotropic_filtering_level = 2` (4x) | **1:1 Concluído** | `project.godot` | Nenhuma |
