# Matriz de Paridade 1:1 — game-x0-moba para Godot 4

Esta matriz rastreia o estado de migração de cada funcionalidade e componente do jogo original para a nova versão Godot 4.

| Sistema / Funcionalidade | Implementação Original (`game-x0-moba`) | Implementação Godot 4 (`game-x1`) | Estado | Testes & Evidências | Divergências Restantes |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Câmera: FOV e Ângulo** | `PerspectiveCamera(38°)`, Offset `(0, 56, 48)` | `Camera3D` com FOV 38°, Offset `(0, 56, 48)` | **Pendente** | Fase 2 | Adaptar MobaCamera para offset e pitch exatos |
| **Câmera: Modo Locked com Folga** | Folga com mouse ratio ($\le 6.0\text{ m}$), lerp 0.08 | Script de câmera com mouse ratio e lerp | **Pendente** | Fase 2 | Integrar cálculo de ratioX/ratioY do viewport |
| **Câmera: Free Mode, Edge Pan & Drag** | Edge threshold 18px, vel 40 u/s, MMB drag 0.05 | Edge pan responsivo e MMB drag | **Pendente** | Fase 2 | Calibrar thresholds para coincidir com o original |
| **Câmera: Teclas Y e Espaço/Quote** | `Y` alterna trava, `'` centraliza no campeão | Action Map com `Y` e `Space` / `Quote` | **Pendente** | Fase 2 | Ambos Space e Quote devem centralizar |
| **Cenário: Chão e Grid 80x80** | Plano `#0a1016`, Grid dourado `#c29d53` / azul `#162838` | Shader ou GridMesh nativo 80x80 com cores exatas | **Pendente** | Fase 2 | Remover antigas muretas e spires do game-x1 |
| **Iluminação & Sombras** | Ambient `#121b26` (1.5), DirLight `#ffffff` (2.0) em (20, 40, 20) | `DirectionalLight3D` e `WorldEnvironment` idênticos | **Pendente** | Fase 2 | Preservar sombras nítidas com alta performance |
| **Caitlyn: Modelo 3D & Escala** | `CaitlynComplete.glb`, escala 0.055, altura 3.5 | Importação GLB no Godot com escala e materiais | **Pendente** | Fase 3 | Configurar import e esqueleto no Godot |
| **Caitlyn: Animação Idle & Run** | `idle1.anm` (1.0x), `run.anm` (2.5x) | `AnimationPlayer` com `playback_speed` 2.5 no Run | **Pendente** | Fase 3 | Mapear nomes de clips do GLB original |
| **Caitlyn: Movimento & Rotação** | Vel 16.0 m/s, rotação suave `diff * 0.25` | `CharacterBody3D` com mesma interpolação angular | **Pendente** | Fase 3 | Garantir resposta idêntica ao clique direito |
| **Inimigo: Dummy Estático** | Cápsula vermelha em `(7, 0, 7)`, 600 HP | Cena `Dummy` com cápsula e olhos idênticos | **Pendente** | Fase 4 | Reproduzir geometria e cor `#9e2a2b` |
| **Inimigo: Dummy Móvel** | Em `(-7, 0, 7)`, vel 2.5 m/s, zigue-zague $\pm 8\text{ m}$ | Cena `Dummy` com modo móvel e rotação $180^\circ$ | **Pendente** | Fase 4 | Garantir mesmo trajeto no eixo X |
| **Inimigo: Outline Vermelho** | Cápsula invertida 0.85x1.65 sólida `#ff0000` | Mesh invertido / shader de contorno vermelho | **Pendente** | Fase 4 | Ativar em hover ou seleção do alvo |
| **Inimigo: Círculo de Tolerância** | Anel roxo de raio 3.0 no chão sob o dummy | Mesh de anel translúcido `#aa00ff` | **Pendente** | Fase 4 | Opacidade de preenchimento 0.04 e borda 0.35 |
| **Inimigo: Flash, Morte & Respawn** | Flash branco 0.1s, tomba 90°, respawn em 3.0s | Timer e troca de material/rotação idênticos | **Pendente** | Fase 4 | Temporizadores exatos de 3 segundos |
| **Combate: Seleção de Alvo (Targeting)**| Prioridade 1: cursor ($\le 5\text{ m}$); Prioridade 2: alcance (18 m) | Classe `TargetingSystem` nativa em GDScript | **Pendente** | Fase 5 | Mesmas tolerâncias e lógica de busca |
| **Combate: Disparo Básico & Windup** | Windup 0.04s, anim 0.12s, attack speed 1.85 | Estados `IDLE`/`ATTACKING` e timers | **Pendente** | Fase 5 | Temporização exata de disparo e animação 3.5x |
| **Combate: Projétil Hextech** | Esfera rosa `#ff007f` (raio 0.12), vel 25 m/s, homing | Cena `Projectile` com modo teleguiado | **Pendente** | Fase 5 | Interpolação até o alvo ou direção linear |
| **Combate: Ataque Melee (Coronhada)** | Alvo $\le 3.2\text{ m}$: dano imediato 55 + faísca amarela | Detecção de distância e spawn de slash amarelo | **Pendente** | Fase 5 | Feedback visual de porrada física |
| **Kiting: Cliques Rápidos & Redução CD**| Cliques de 0.10s-0.42s: +15% AS (até +45%), -0.14s CD | Lógica de temporizador e redução de cooldown | **Pendente** | Fase 6 | Mesma mecânica de kiting responsivo |
| **Kiting: Attack Move (Tecla A)** | Tecla A ativa círculo vermelho de alcance e clique esquerdo | Action Map e modo Attack Move | **Pendente** | Fase 6 | Círculo vermelho com opacidade 0.35 |
| **UI: Indicador de Clique no Chão** | `pointTarget.glb` verde `#00ff88`, gira 6 rad/s, 0.35s | Importação de `pointTarget.glb` ou equivalente 1:1 | **Pendente** | Fase 7 | Mesma animação de escala e rotação |
| **UI: Placas de Vida Flutuantes** | Caitlyn (nível 5, HP verde, mana azul); Dummies (dourado/vermelho)| `CanvasLayer` com nós `Control` projetados 3D->2D | **Pendente** | Fase 7 | Estilo visual LoL com divisores a cada 100 HP |
| **UI: Números de Dano** | Laranja `#ff9f00` (26px), Crítico vermelho `#ff3300` (34px) | Labels estilizados com contorno preto subindo $3.2\text{ m/s}$ | **Pendente** | Fase 7 | Mesma física de subida e desvanecimento 0.8s |
| **UI: Status HUD & Controles** | Card escuro no topo esquerdo com borda dourada | Card equivalente com texto e telemetria | **Pendente** | Fase 7 | Mesma tipografia e informações |
| **UI: Cursores Customizados** | `normal.cur`, `alt.cur` (espada vermelha), `link.cur` | `Input.set_custom_mouse_cursor()` | **Pendente** | Fase 7 | Cursores oficiais de League of Legends |
