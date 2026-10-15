# Plano de Execução da Migração 1:1 — game-x0-moba para Godot 4

Este documento define o roteiro detalhado de migração do jogo `game-x0-moba` para `game-x1` na branch `port/game-x0-1to1`.

---

## Fases de Execução

### ✅ Fase 0: Preparação do Ambiente e Repositório
- [x] Checkout da branch `port/game-x0-1to1` rastreando a referência remota.
- [x] Confirmação da integridade de leitura do repositório `game-x0-moba` sem qualquer alteração destrutiva.
- [x] Validação das ferramentas de compilação (Node, TypeScript, Godot CLI v4.7.2).

### ✅ Fase 1: Engenharia Reversa e Baseline
- [x] Leitura e análise de todos os arquivos do código original (`Game.ts`, `Camera.ts`, `Input.ts`, `Targeting.ts`, `Character.ts`, `Dummy.ts`, `Projectile.ts`, `style.css`, `index.html`).
- [x] Criação de `docs/migration/GAME_X0_REVERSE_ENGINEERING.md`.
- [x] Criação de `docs/migration/REFERENCE_BASELINE.md`.
- [x] Criação de `docs/migration/PARITY_MATRIX.md`.
- [x] Criação de `docs/migration/ASSET_LICENSE_AUDIT.md`.

### 🔄 Fase 2: Reconstrução do Cenário e Câmera
- [ ] Limpeza do cenário antigo do `game-x1` (remover muretas, pilastras, spires de time e dummies palito).
- [ ] Criação do chão $80 \times 80$ em `#0a1016` com grid de desenvolvimento $2 \times 2$ nas cores `#c29d53` (primária) e `#162838` (secundária).
- [ ] Configuração de iluminação idêntica: ambiente `#121b26` (1.5) e direcional `#ffffff` (2.0 em $(20, 40, 20)$ com sombras limpas).
- [ ] Reconstrução do controlador de câmera:
  - FOV $38^\circ$, offset base $(0, 56, 48)$, pitch de $\approx 49,4^\circ$.
  - Modo `isLocked = true` como padrão com folga do cursor (`maxLockOffset = 6.0`, lerp 0.08).
  - Modo livre com edge scrolling ($\le 18\text{px}$, vel 40 u/s) e arrasto com MMB (`dragSpeed = 0.05`).
  - Suporte às teclas `Y` (toggle trava) e `Space` / `Quote` (centralizar).
  - Limites do mapa clamped em $\pm 38$.

### 🔄 Fase 3: Importação da Caitlyn e Movimentação
- [ ] Copiar `CaitlynComplete.glb` para o projeto Godot em `assets/characters/caitlyn/`.
- [ ] Configurar cena e materiais PBR da Caitlyn com escala $0.055$.
- [ ] Configurar `AnimationPlayer` com animações `idle` e `run` (com `playback_speed = 2.5`).
- [ ] Implementar movimentação via clique direito a $16.0\text{ m/s}$ com parada precisa.
- [ ] Implementar rotação angular idêntica: `diff * 0.25` por frame.

### 🔄 Fase 4: Inimigos (Dummies Estático e Móvel)
- [ ] Criar cena do `Dummy` com cápsula vermelha `#9e2a2b` e olhos `#ff3b30`.
- [ ] Implementar contorno vermelho espesso (`outlineMesh` com faces invertidas `#ff0000`).
- [ ] Criar círculo roxo de tolerância de clique no chão (raio 3.0, opacidade 0.04/0.35).
- [ ] Instanciar o Dummy Estático em $(7, 0, 7)$ e o Dummy Móvel em $(-7, 0, 7)$.
- [ ] Implementar movimentação do dummy móvel a $2.5\text{ m/s}$ em zigue-zague de $\pm 8.0\text{ m}$ com rotação de $180^\circ$.
- [ ] Implementar flash branco de dano ($0.1\text{ s}$), animação de morte (tombo de $90^\circ$) e respawn após $3.0\text{ s}$.

### 🔄 Fase 5: Combate Básico e Projéteis
- [ ] Implementar classe `TargetingSystem` com busca em 2 etapas (cursor primeiro em raio 5.0, depois proximidade do jogador em raio 18.0).
- [ ] Implementar estado `ATTACKING` da Caitlyn:
  - Windup de $0.04\text{ s}$, animação de tiro acelerada a $3.5\times$, attack speed base $1.85$.
  - Disparo de projétil Hextech rosa `#ff007f` (esfera raio 0.12, vel 25 m/s) teleguiado até o alvo.
  - Ataque melee corpo a corpo quando alvo estiver a $\le 3.2\text{ m}$ (dano instantâneo 55 + efeito visual de faísca amarela).
- [ ] Dano base de 55 com 25% de chance de crítico ($96$).

### 🔄 Fase 6: Mecânica de Kiting e Attack Move
- [ ] Rastreamento de cliques rápidos ($0.10\text{ s}$ a $0.42\text{ s}$):
  - Bônus cumulativo de $+15\%$ até $+45\%$ na velocidade de ataque por $1.0\text{ s}$.
  - Redução de $0.14\text{ s}$ no cooldown restante por clique rápido durante o kiting.
- [ ] Cancelamento imediato de ataque (`cancelAttack`) ao emitir ordem de movimento no chão.
- [ ] Modo Attack Move na tecla `A` com círculo vermelho de alcance e clique esquerdo.
- [ ] Tecla `X` para ataque direcional / Wild Rift.

### 🔄 Fase 7: Interface, HUD e Efeitos Visuais
- [ ] Importar `pointTarget.glb` e reproduzir o efeito verde de clique (escala 1.5, giro 6 rad/s, fade 0.35s).
- [ ] Criar placas de vida flutuantes:
  - Caitlyn: nível 5, barra verde de HP com ticks a cada 100 HP, barra azul de Mana, textos de vida.
  - Dummies: borda dourada, barra vermelha de HP com ticks, nome e HP quantitativo.
- [ ] Criar números de dano flutuantes em fonte estilo Outfit (laranja 26px e crítico vermelho 34px).
- [ ] Configurar cursores customizados de League of Legends (`normal.cur`, `alt.cur`, `link.cur`).
- [ ] Recriar Card de Status no topo esquerdo com dados do jogo e lista de atalhos.

### 🔄 Fase 8: Validação Comparativa Lado a Lado
- [ ] Executar ambos os jogos na mesma resolução e registrar alinhamento de câmera, escala e cores.
- [ ] Testar kiting contínuo e verificar se o tempo de resposta e fluidez são idênticos.
- [ ] Ajustar eventuais divergências de sensibilidade ou tolerância.

### 🔄 Fase 9: Otimização e Exportação Web Final
- [ ] Medir desempenho (manter alvo de 120 FPS na GPU de referência).
- [ ] Exportar Web via `scripts/export_web.ps1`.
- [ ] Validar no Chrome em janela normal e fullscreen.
- [ ] Atualizar `HANDOFF.md` e `PROGRESS.md`.
