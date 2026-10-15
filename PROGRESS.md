# Progresso — game-x1 (Port 1:1 game-x0-moba -> Godot 4)

**Atualizado:** 2026-10-15  
**Branch:** `port/game-x0-1to1`  
**Fase:** Migração 1:1 de `game-x0-moba` para Godot 4. Personagem Caitlyn 3D (`CaitlynComplete.glb`), Dummies Estático e Móvel, Combate Ranged/Melee, Projéteis Hextech, Kiting com bônus de AS, Sistema de Alvo Wild Rift, Cursors LoL e Interface Flutuante com placa LoL e números de dano concluídos e verificados em 5 suítes automatizadas.  
**Fonte de verdade:** commits + este arquivo. Nunca marcar como concluído sem evidência real.

## Situação verificada na branch `port/game-x0-1to1`

- [x] **Fase 0 & 1 — Engenharia Reversa e Especificações 1:1:**
  - Repositório de referência `game-x0-moba` analisado e documentado em `docs/migration/`.
  - Documentos criados: `GAME_X0_REVERSE_ENGINEERING.md`, `PARITY_MATRIX.md`, `REFERENCE_BASELINE.md`, `MIGRATION_PLAN.md` e `ASSET_LICENSE_AUDIT.md`.
- [x] **Fase 2 — Cenário e Câmera 1:1:**
  - Chão 80x80 com shader de grid idêntico ao Three.js (`#0a1016` base, `#c29d53` dourado central, `#162838` células).
  - Câmera LoL (`scenes/moba_camera.gd`): FOV 38°, offset base `(0, 56, 48)` (pitch 49,4°, yaw 0° alinhado aos eixos), travada com offset do cursor, edge scroll 40 u/s, MMB drag, limites ±38m, centralização em Espaço/' e alternância em Y.
- [x] **Fase 3 — Importação de Modelos e Assets Oficiais:**
  - `CaitlynComplete.glb` (36.9 MB) importado e configurado com animações (`idle1_anm`, `run_anm`, `attack1_anm`).
  - `pointTarget.glb` importado com rotação e escala dinâmica.
  - Cursores oficiais do LoL (`normal.png`, `alt.png`, `link.png`) convertidos e ativos via `Input.set_custom_mouse_cursor`.
- [x] **Fase 4 — Personagem Caitlyn e Combate 1:1:**
  - Caitlyn (`scenes/hero/caitlyn.gd`, `hero.tscn`): escala 0.055, velocidade 16.0 m/s, HP 1072, alcance 18.0 m, attack speed base 1.85.
  - Animações sincronizadas: `run` a 2.5x, `attack` a 3.5x acelerada com bônus de kiting.
  - Mecânica de kiting por cliques rápidos: intervalos de 0.10s–0.42s concedem +15% AS por clique (máx +45%), cliques em cooldown reduzem 0.14s do tempo restante.
  - Ataque Melee (Coronhada de rifle): distância $\le 3.2$ m causa 55 de dano instantâneo com faísca amarela sem gerar projétil.
  - Projétil Rosa Hextech (`scenes/combat/projectile.tscn`): velocidade 25.0 m/s, dano 55 (crítico 96), teleguiado e direcional.
  - Dummies (`scenes/arena/dummy.tscn`): Estático em `(7, 0, 7)` e Móvel em `(-7, 0, 7)` oscilando $\pm 8$ m na velocidade 2.5 m/s, 600 HP, círculo de tolerância roxo de 3.0 m, outline vermelho grosso no hover/seleção, flash de dano branco e respawn em 3.0s.
  - Sistema de Alvo (`scripts/targeting_system.gd`): prioriza dummy próximo ao mouse (raio 5.0 m) ou dummy mais próximo à Caitlyn (18.0 m).
- [x] **Fase 5 — Interface Flutuante e HUD 1:1:**
  - Placa do Jogador LoL (`scenes/ui/floating_bars.gd`): projetada acima da cabeça ($y+5.2$), texto "Caitlyn", "1072 / 1072 (100%)" em ciano `#00ffcc`, caixa de nível "5" com borda dourada, barra de vida verde com 10 ticks de 100 HP e barra de mana azul.
  - Barra de Vida dos Dummies: moldura dourada `#c29d53`, barra vermelha com ticks de 100 HP e texto quantitativo.
  - Números de Dano Flutuantes (`scenes/ui/floating_damage.gd`): 26px laranja bold (55) ou 34px vermelho bold com "!" (96 crit, 25% de chance), contorno preto espesso, flutuando a 3.2 u/s durante 0.8s.
  - Indicador de alcance circular (raio 18.0) verde (opacidade 0.08) ou rosa/vermelho (0.35) no modo Attack Move (tecla A).
  - Marcador de alvo selecionado vermelho pulsante.
  - Indicador de clique verde animado com `pointTarget.glb` que gira e reduz de escala em 0.35s.
- [x] **Validação Automatizada Quíntupla (`scripts/test.ps1`):**
  - 1/5: Import & parse do editor headless.
  - 2/5: Smoke check de 60 frames.
  - 3/5: Movimento determinístico e parada sem overshoot (`test_movement.gd`).
  - 4/5: 7 verificações de câmera e limites (`test_camera.gd`).
  - 5/5: 7 verificações de combate, dummies, projéteis, kiting e targeting (`test_combat.gd`).
- [x] **Exportação Web Atualizada (`build/web/`):**
  - Pacote Web gerado com sucesso via `scripts/export_web.ps1`.
  - Servido localmente em `http://localhost:8080/`.
## Próximos incrementos

**0. Fundação e prova Web**
- [x] Projeto Godot 4.x com cena 3D, chão, luz e câmera inclinada.
- [x] Comando/script para importar e executar pelo terminal (`scripts/test.ps1`, `scripts/run.ps1`).
- [x] Exportação Web funcional gerando HTML/WASM/PCK (`scripts/export_web.ps1`) e servida com headers COOP/COEP (`scripts/serve_web.ps1`).
- [x] Captura real da cena Web no Chrome (chão, cubo/sombra, câmera, HUD, ~60 FPS).
- [ ] Teste simples para Windows; avaliação inicial das limitações Android.

**1. Herói e movimentação**
- [x] (1A) Boneco-palito 3D articulado com segmentos/juntas visíveis, Idle e Run (visual de desenvolvimento, sem arte final).
- [x] (1A) Clique para mover com botão direito, rotação coerente e parada sem overshoot.
- [x] (1A Refinada) Arena isométrica escura com muretas, pilastras, spires de time, 4 dummies inimigos e anel de seleção.
- [x] (UX/Câmera) Câmera estilo League of Legends com otimização completa para modo janela Web (edge pan responsivo, MMB drag, Espaço sem scroll de página, Y, zoom suave, limites e HUD).
- [ ] (1B) Esquiva (Shift) com animação, cooldown e colisão.

**2. Combate básico**
- [ ] Ataque e HP/dano/morte.
- [ ] Q/W/E/R com alvos, tempos, efeitos e testes.
- [ ] HUD legível.

**3. Partida 1v1 contra bot**
- [ ] Lane, duas bases, uma torre por lado.
- [ ] Minions e bot funcional.
- [ ] Vitória/derrota/respawn/reinício e balanceamento inicial.

**4. Aprimoramento de gameplay**
- [ ] Melhorar game feel, animações, VFX, UX e desempenho Web.
- [ ] Definir se vale incorporar um Godot MCP e validar o ganho real.

**5. 1v1 online**
- [ ] Simulação/servidor autoritativo, conexão de dois clientes e sincronização.
- [ ] Testes de latência, divergência de estado, desconexão e reconexão.

## Regras para atualizar

Registrar por incremento: commit, funcionalidade jogável, comando/teste executado, resultado, captura real (quando visual) e limitações. Não reportar aprovação estética sem playtest humano.

**Próxima tarefa para o Antigravity:** Após validação humana da navegação de câmera na janela do navegador, implementar a Etapa 1B (esquiva no Shift com recarga e rastro/feedback visual).
