# Progresso — game-x1

**Atualizado:** 2026-10-15  
**Fase:** Etapa 0 com renderização Web confirmada por captura do usuário; próximo incremento Etapa 1A. Animação do cubo/console e execução nativa seguem sem confirmação independente.  
**Fonte de verdade:** commits + este arquivo. Nunca marcar como concluído sem evidência real.

## Situação verificada

- [x] Repositório GitHub `victorwilliames/game-x1` criado e sincronizado.
- [x] Primeira documentação técnica/visual e escopo do jogo registrados.
- [x] Godot 4 disponível e sua versão registrada na máquina de desenvolvimento (`Godot v4.7.2.stable.official.ed1daf0bf`).
- [x] Projeto Godot mínimo criado no repositório com cena 3D (chão, iluminação direcional com sombras, marcador central e câmera inclinada).
- [x] Exportação Web (GL Compatibility) gerada e validada via CLI.
- [x] Pipeline reproduzível CLI para testar (`test.ps1`), exportar (`export_web.ps1`), rodar (`run.ps1`) e servir localmente (`serve_web.ps1`).

## Próximos incrementos

**0. Fundação e prova Web**
- [x] Projeto Godot 4.x com cena 3D, chão, luz e câmera inclinada.
- [x] Comando/script para importar e executar pelo terminal (`scripts/test.ps1`, `scripts/run.ps1`).
- [x] Exportação Web funcional gerando HTML/WASM/PCK (`scripts/export_web.ps1`) e servida com headers COOP/COEP (`scripts/serve_web.ps1`).
- [x] Captura real da cena Web no Chrome (chão, cubo/sombra, câmera, HUD, ~60 FPS). A captura não comprova rotação do cubo nem console sem erros.
- [ ] Teste simples para Windows; avaliação inicial das limitações Android.

**1. Herói e movimentação**
- [ ] Boneco-palito 3D articulado com segmentos/juntas visíveis, Idle e Run (visual de desenvolvimento, sem arte final).
- [ ] Clique para mover, rotação coerente, câmera acompanhando.
- [ ] Esquiva (Shift) com animação, cooldown e colisão.

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

**Próxima tarefa para o Antigravity:** Etapa 1A: boneco-palito 3D articulado, Idle/Run, movimento por clique direito e câmera acompanhando; não iniciar ainda esquiva ou combate. Validar Web, atualizar HANDOFF e publicar.
