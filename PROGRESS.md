# Progresso — game-x1

**Atualizado:** 2026-10-15  
**Fase:** Etapa 1A refinada (arena isométrica estilo combat testing lane, muretas e pilastras com acentos de time, estruturas de base com cristais, anel de seleção do herói, 4 dummies inimigos, correção da Issue #2 de clique e overshoot, e teste determinístico headless).  
**Fonte de verdade:** commits + este arquivo. Nunca marcar como concluído sem evidência real.

## Situação verificada

- [x] Repositório GitHub `victorwilliames/game-x1` criado e sincronizado.
- [x] Primeira documentação técnica/visual e escopo do jogo registrados.
- [x] Godot 4 disponível e sua versão registrada na máquina de desenvolvimento (`Godot v4.7.2.stable.official.ed1daf0bf`).
- [x] Projeto Godot mínimo criado no repositório com cena 3D (chão, iluminação direcional com sombras, marcador central e câmera inclinada).
- [x] Exportação Web (GL Compatibility) gerada e validada via CLI.
- [x] Pipeline reproduzível CLI para testar (`test.ps1`), exportar (`export_web.ps1`), rodar (`run.ps1`) e servir localmente (`serve_web.ps1`).
- [x] Prova visual inicial Web da Etapa 0 confirmada por captura no Chrome (60 FPS).
- [x] Personagem 3D estilo boneco-palito articulado (`scenes/hero/stick_figure.tscn`) com juntas e membros nativos.
- [x] Animações procedurais nativas de `Idle` (respiração) e `Run` (passadas e braços alternados) sincronizadas com a velocidade horizontal.
- [x] Anel de seleção circular no chão sob os pés do herói (`SelectionRing`, ciano emissivo).
- [x] Movimentação por clique no chão com raycast físico restrito à arena e sem overshoot (`step_speed = min(move_speed, distance / delta)`).
- [x] Teste determinístico automatizado de movimentação e chegada precisa sem oscilação (`scripts/test_movement.gd` incluído no `scripts/test.ps1`).
- [x] Câmera isométrica aproximada e configurável (yaw 45°, pitch 38°, zoom com scroll do mouse), valorizando o herói e a arena.
- [x] Shader de chão de laboratório refinado com grid sutil, cruzes nos vértices, linha pontilhada central e gradiente suave de time.
- [x] Limites da arena e muretas modulares com pilastras e acentos de iluminação de time (ciano no lado aliado, vermelho no lado inimigo).
- [x] Estruturas de base com pedestal escalonado escuro e cristais flutuantes com rotação (ciano aliado / vermelho inimigo).
- [x] Quatro dummies de teste inimigos vermelhos em postura de combate com barras de vida simples para referência de escala e composição.

## Próximos incrementos

**0. Fundação e prova Web**
- [x] Projeto Godot 4.x com cena 3D, chão, luz e câmera inclinada.
- [x] Comando/script para importar e executar pelo terminal (`scripts/test.ps1`, `scripts/run.ps1`).
- [x] Exportação Web funcional gerando HTML/WASM/PCK (`scripts/export_web.ps1`) e servida com headers COOP/COEP (`scripts/serve_web.ps1`).
- [x] Captura real da cena Web no Chrome (chão, cubo/sombra, câmera, HUD, ~60 FPS).
- [ ] Teste simples para Windows; avaliação inicial das limitações Android.

**1. Herói e movimentação**
- [x] (1A) Boneco-palito 3D articulado com segmentos/juntas visíveis, Idle e Run (visual de desenvolvimento, sem arte final).
- [x] (1A) Clique para mover com botão direito, rotação coerente e câmera acompanhando suavemente.
- [x] (1A Refinada) Arena isométrica escura com muretas, pilastras, spires de time, 4 dummies inimigos, anel de seleção e resolução da Issue #2.
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

**Próxima tarefa para o Antigravity:** Após validação humana da nova arena e movimentação no navegador, implementar a Etapa 1B (esquiva no Shift com recarga e rastro/feedback visual).
