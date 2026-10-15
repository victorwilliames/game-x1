# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Migração integral 1:1 de `game-x0-moba` para Godot 4 concluída até a Fase 5. Caitlyn 3D oficial (`CaitlynComplete.glb`), Dummies Estático e Móvel, Combate Ranged e Melee, Projétil Hextech, Kiting com bônus de velocidade e cancelamento, Sistema de Alvo Wild Rift, Cursors LoL, Indicadores 3D (Range 18m, Target Marker pulsante, PointTarget animado) e Interface Flutuante (Placa LoL do jogador com nível 5, mana e ticks de 100 HP, barras de vida com moldura dourada para inimigos e números de dano flutuantes) implementados e verificados em 5 suítes automatizadas. Exportação Web gerada e ativa em `http://localhost:8080/`.  
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
4. **Interface e Cursors Oficiais:**
   - Placa do jogador LoL com nível 5, nome "Caitlyn", texto quantitativo de HP, barra de vida verde com 10 divisores pretos de 100 HP e barra de mana azul.
   - Barra de vida dos inimigos com moldura dourada `#c29d53` e ticks de 100 HP.
   - Números de dano flutuantes grandes (26px laranja / 34px vermelho com "!" para críticos) com borda preta espessa.
   - Cursores do LoL (`normal.png`, espada vermelha `alt.png` ao mirar no inimigo e `link.png` no modo Attack Move).
   - Câmera LoL com travamento suave, edge scrolling, zoom, arrasto com MMB e centralização em Espaço / `'`.

## 2. Arquivos alterados / criados

- `scenes/hero/caitlyn.gd`: controlador da Caitlyn (16 m/s, HP 1072, alcance 18m, kiting, windup 0.04s, animações).
- `scenes/hero/hero.tscn`: cena do herói atualizada para instanciar `CaitlynComplete.glb` e `caitlyn.gd`.
- `scenes/arena/dummy.gd` & `dummy.tscn`: dummy com cápsula vermelha `#9e2a2b`, outline `#ff0000`, anel roxo 3m, dano, flash e respawn.
- `scenes/combat/projectile.gd` & `projectile.tscn`: projétil rosa Hextech 25 m/s com lógica teleguiada e direcional.
- `scripts/targeting_system.gd`: port 1:1 de `TargetingSystem.ts` com prioridade para cursor (5m) ou jogador (18m).
- `scenes/ui/floating_bars.gd`: desenho de placa LoL da Caitlyn e barras inimigas douradas com projeção de tela.
- `scenes/ui/floating_damage.gd`: números de dano flutuantes laranja/vermelho com contorno preto 3D.
- `scenes/main.gd` & `main.tscn`: orquestrador de combate, dummies, projéteis, indicadores, cursors e telemetria.
- `scripts/test_combat.gd`: suíte com 7 testes automatizados de combate, atributos, dummies, kiting e projéteis.
- `scripts/test.ps1`: pipeline atualizado executando 5/5 suítes automatizadas.
- `assets/ui/pointers/`: cursores oficiais convertidos para PNG (`normal.png`, `alt.png`, `link.png`).
- `PROGRESS.md`: progresso registrado com as 5 fases concluídas.

## 3. Estado das validações

- **verified:** Suíte quíntupla (`scripts/test.ps1`) com código de saída 0:
  - 1/5: Import & parse do editor headless.
  - 2/5: Smoke check de 60 frames.
  - 3/5: Movimento determinístico e parada sem overshoot (`test_movement.gd`).
  - 4/5: 7 verificações de câmera e limites (`test_camera.gd`).
  - 5/5: 7 verificações de combate, dummies, projéteis, kiting e targeting (`test_combat.gd`).
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerando pacote atualizado em `build/web/`.
- **verified:** Servidor web ativo servindo a versão 1:1 atualizada em `http://localhost:8080/`.

## 4. Próxima ação / comando

1. Testar e comparar lado a lado no navegador em `http://localhost:8080/`.
2. Fazer commit e push exclusivamente na branch `port/game-x0-1to1`.
